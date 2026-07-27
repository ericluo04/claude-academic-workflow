--- stage-slide.lua
--- Make a slide open as its title alone, then reveal its content one beat at a time.
---
--- `incremental: true` only stages list items. A paragraph, a callout, a table, a
--- figure, or a theorem block still lands with the heading, so a slide that mixes
--- prose and a list appears half-built. This filter stages every top-level block on
--- a content slide, so the slide starts as just its heading and each block arrives
--- on its own beat, top to bottom.
---
--- THE INVARIANT. On a content slide, nothing but the heading is visible at
--- fragment step 0. The only exemptions are slides that carry no content by
--- construction (`.section-break`, `.appendix-break`, `.references-break`, a
--- level-1 divider), the reference list (`.references`, which is a list and not an
--- argument), a slide the author opted out with `{.no-stage}`, and blocks that are
--- not content at all (speaker notes, the slide footer, `{visibility="hidden"}`
--- material). Everything else on the slide is staged, including a figure.
---
--- Verify it mechanically, not by eye. `stage-check.mjs` beside this file drives
--- reveal to step 0 on every slide and asserts that the only visible text and the
--- only visible graphic belong to the heading.
---
--- Usage, in the deck front matter:
---   filters:
---     - ~/.claude/assets/quarto-yale/stage-slide.lua
---
--- Opt a single slide out with `{.no-stage}` on its heading:
---   ## Everything at once {.no-stage}
---
--- GROUPING. A `.together` div is one beat: everything inside it arrives on a
--- single keypress, and a list inside it is marked `.nonincremental` so it does
--- not re-stage itself item by item.
---
---   ::: {.together}
---   The level effect is a wash.
---
---   The interaction is not.
---   :::
---
--- Explicit `fragment-index` on your own `.fragment` still works and is untouched;
--- equal indices fire together. See the index note at the bottom of this comment
--- for when the filter adds indices of its own.
---
--- ADDENDA. A note that annotates the block above it should not cost a keypress.
--- Blocks carrying `.aside-note`, `.citation`, `.cite`, `.caption`, or the
--- explicit `.with-previous` arrive on the same beat as the block before them. A
--- figure caption written as `![cap](f.png)` already travels inside its own Figure
--- block and needs none of this.
---
--- FIGURES are the case that forced the design here, so it is worth spelling out.
--- Quarto's `auto-stretch` is not a Lua filter; it is a DOM pass that runs after
--- pandoc (`applyStretch` in the revealjs writer). On a slide holding exactly one
--- image it adds `.r-stretch` to that image and then HOISTS the image out to be a
--- direct child of the `<section>`, because reveal only ever sizes
--- `section > .r-stretch`. It refuses to touch an image that has an ancestor
--- carrying `.fragment`.
---
--- So a figure cell cannot be wrapped. A wrapper blocks the stretch outright, and
--- if the stretch did run the hoist would carry the image out of the wrapper and
--- leave it unstaged. Two things follow:
---
---   * The filter stages a cell whose only visible content is one image by putting
---     `.fragment` on the IMAGE itself. The class rides along when the image is
---     moved, the ancestor test looks only at ancestors, and the hoisted
---     `<img class="fragment r-stretch">` ends up both staged and stretched, at
---     exactly the size it had before it was staged. Measured on the sample talk:
---     864x454 before, 864x454 after.
---   * Anything else in the cell (echoed source, a caption, a second image) means
---     the hoist would leave content behind, so the whole cell is wrapped instead
---     and the stretch is lost. The image then renders at its authored width. That
---     is a visible size change, not a silent one: `deck-check.mjs fit` fails a
---     figure that shrank and fails a slide that overflows, so the gate catches it
---     either way. A caption is the case to know about, because `applyStretch`
---     moves a figcaption out to a sibling `<p class="caption">` that no wrapper
---     could reach.
---
--- Do not add `.r-stretch` by hand inside a fragment. It is not a workaround for
--- the nesting rule: reveal never sizes a nested element, and `.r-stretch` also
--- clears the `max-width`/`max-height` that were holding the image inside the
--- canvas, so the image comes out at its natural size and overflows.
---
--- TABLES are always one beat, whatever their source. A pipe table and a `Table`
--- node are single blocks already. Raw HTML is the case that bit: pandoc parses
--- `<table class="spec">...` into one RawBlock per tag with the cell text as
--- separate `Plain` blocks, so wrapping block by block staged every number on its
--- own beat. The filter collapses a run of raw HTML that opens a container into
--- one unit and wraps the run, so the cells inside are never staged.
---
--- LISTS are left to `incremental: true`, which stages them item by item. The
--- filter reads `PANDOC_WRITER_OPTIONS.incremental` rather than assuming it: with
--- `incremental: false` a list is not staged by anyone, so the filter wraps it as
--- one beat instead of letting it land with the heading.
---
--- NESTED STAGING. A few containers have their insides staged by reveal, by
--- Quarto, or by the author: `.incremental` (its list), `.r-stack` / `.r-hstack` /
--- `.r-vstack` (their `.fragment` children). Wrapping one of those would nest a
--- fragment inside a fragment and spend the outer beat on nothing, so they pass
--- through, but only when the first visible thing inside them is itself staged.
--- When it is not (a `.nonincremental` list, an `.r-stack` whose base layer is a
--- plain image, a `.quarto-layout-panel`), that first thing would otherwise land
--- with the heading, so the container is wrapped after all and the inner fragments
--- follow the outer beat. A cell with `output-location: fragment` is wrapped for
--- the same reason and comes out right: the echoed source arrives on the outer
--- beat and the output on the inner one.
---
--- SECTION DIVIDERS are left alone, except for one thing: the filter counts
--- `.section-break` headings and writes the running number onto each as
--- `data-section-number`, plus the deck's total as `data-section-total`, and
--- pandoc moves both to the slide's `<section>` element. Both themes draw the
--- number in the circle on the divider with `content: attr(data-section-number)`.
--- Dividers are never hand-numbered. A theme with no rule for either attribute
--- ignores it. `data-section-total` is drawn by neither theme now that the "of N"
--- under the lecture disc is gone, and it stays on the heading anyway: a theme
--- might want it again, and taking it out would be a filter change for no gain.
---
--- The total needs its own pass over the document, because the first divider has
--- to know a number that only the last divider establishes.
---
--- A CSS counter is the obvious way to do this and it does not work here. reveal
--- has a `viewDistance` (3 by default) and sets `display: none` on every slide
--- outside it, and a `display: none` element does not increment a CSS counter, so
--- the number came out as a function of which slides happened to be rendered:
--- four dividers numbered 1, 2, 2, 2. Verified in headless Chrome.
---
--- PROGRESS SEGMENTS. When a deck has two or more `.section-break` dividers the
--- filter emits a small script that cuts reveal's bottom progress bar into one
--- segment per section, so a glance shows both how far the class has gone and
--- which block it is in. The positions have to be computed at run time from
--- `Reveal.getSlides()`: reveal drops `data-visibility="hidden"` slides from the
--- DOM, counts the title slide, and skips `.stack` wrappers, so a build-time guess
--- at its slide numbering would put the cuts in the wrong places. The script only
--- writes CSS custom properties; the theme decides whether to draw anything, and a
--- theme with no `.progress` rule for them is unaffected.
---
--- THE APPENDIX AND THE REFERENCES ARE OUTSIDE THE BAR. The same script takes the
--- fill over from reveal so that everything past the argument counts for nothing:
--- it is not in the denominator and it gets no segment, so the bar reads 100% at
--- the closing slide. A twelve-slide appendix plus three slides of references would
--- otherwise leave the closing slide at about half and tell the room the talk was
--- nowhere near over. Past that line the bar stays full, because the main deck
--- really is finished and a bar that receded on entering the appendix would be a
--- worse lie than one that sat at 100%. Both dividers are still boundaries: they
--- keep their own ground and ring, they just get no cut, and a cut there would land
--- on the right edge anyway. The four classes that mean "past the main deck" live
--- in ONE predicate, `pastMain`, spliced into both emitted scripts, with
--- `leaves_main` as its Lua twin.
---
--- THE CLOSING SLIDE IS WHERE THE BAR FILLS, and it says so by name: `.thanks-slide`
--- on a talk, `.closing-slide` on a lecture. `isClosing` is the second spliced
--- predicate, `is_closing` its Lua twin. Naming the slide rather than inferring it
--- from what follows buys two things. A slide added after the closing one (a
--- backup, a contact card) no longer moves the point where the bar completes, and
--- the last step of the bar is reserved: a staged slide one press short of the
--- closing slide holds at (n-1)/n instead of creeping to 0.994 of full on its own
--- fragments and reading as finished a slide early.
---
--- THE SLIDE NUMBER RESTARTS THERE TOO. `slide-number: c/t` puts the whole deck
--- in the denominator, so a 19-slide argument with an appendix and a reference
--- list behind it opens at 1/26 and closes at 19/26, which reads as two thirds of
--- the way through a talk that is over. The same script hands reveal a
--- `slideNumber` function running off the same `mainCount`: the main body is
--- 1/19 through 19/19 and ends on the closing slide, and the appendix and the
--- references share one run of their own after it, 1/7 through 7/7, one
--- denominator across both. Reusing the bar's boundary is the point. A second
--- count computed here could drift from the fill, and a bar that reads 100% on a
--- slide numbered 19/26 is worse than either error alone.
---
--- reveal takes `slideNumber` as a function returning `[current, delimiter,
--- total]`, which is the array its own `c/t` branch builds, so the markup stays
--- reveal's: the `<a href>` the keyboard can reach and the three spans the themes
--- colour. The alternative, rewriting `.slide-number` on `slidechanged` the way
--- the bar is rewritten, would have to win a race with every other path that
--- calls the controller's `update()` (a sync, a resize, leaving the overview),
--- each of which paints `c/t` back over it.
---
--- The printed handout is on a different path and is untouched by any of this.
--- reveal's print view builds its own `.slide-number-pdf` per page from a running
--- counter (`innerHTML = v++`) and never calls `getSlideNumber`, so a handout page
--- carries a bare page number with no denominator, before and after.
---
--- MEASURING THE BAR. Read it settled or not at all. reveal's own
--- `.reveal .progress span` carries `transition: transform 800ms
--- cubic-bezier(.26,.86,.44,.985)`, and the substituted span is a clone of it, so a
--- probe that drives `Reveal.slide()` and reads `getComputedStyle(...).transform`
--- a tenth of a second later samples a point on that curve and not the value the
--- script wrote. It comes back as a smooth asymptote across the whole deck
--- (87%, 93%, 97%, 98%, 99%, 100%), which looks exactly like reveal's native
--- `getProgress()` and reads as "the takeover never happened". It had happened.
--- Either sleep past 800ms per slide or stamp `transition: none` on the span before
--- driving the deck.
---
--- REFERENCES. A deck with a `bibliography:` gets its reference list paginated
--- across as many slides as it needs, automatically:
---
---   ## References {.references-break background-color="var(--references-ground)"}
---
---   ## References {.references}
---
---   ::: {#refs}
---   :::
---
--- and `citeproc: false` in the front matter, because the filter runs citeproc
--- itself. The references section goes at the very end, after the appendix. See the
--- references block further down for why citeproc has to run from in here, where
--- the empty `#refs` marker ends up, and how the entries-per-slide budget was
--- measured. Nothing on a references slide is staged.
---
--- JUMP BUTTONS. `[Robustness]{.jump target="ap-window"}` on a main slide becomes
--- a button that jumps to the slide with that id, and `[Back]{.jump-back}` on the
--- appendix slide returns to the exact slide and fragment step the jump started
--- from. An empty `[]{.jump-back}` reads "Back", which is the label a return
--- button wants almost every time. See the jump-buttons section below for the
--- mechanism.
---
--- INDEX NOTE. reveal sorts fragments carrying `data-fragment-index` ahead of
--- every fragment that has none (`Fragments.sort`: indexed groups first, then the
--- unindexed ones in DOM order). Pandoc writes `<li class="fragment">` with no
--- index, so numbering the blocks on a slide that also has a staged list would
--- push its bullets to the end of the slide. The filter therefore numbers the
--- beats only when it can account for every fragment on the slide: no staged
--- list, no `.fragment` of your own, and none of the containers whose insides
--- something else stages (`.r-stack`, `.r-hstack`, `.r-vstack`,
--- `.quarto-layout-panel`, a `.cell` with `output-location: fragment`). On those
--- slides an addendum gets its own div with the previous beat's index. Elsewhere
--- the filter leaves the indices off, which keeps DOM order authoritative, and
--- places the addendum inside the preceding block's fragment (or inside the last
--- item of the preceding list) so it still arrives on the same beat. One case
--- cannot have it both ways: an addendum under a lone image on an unnumbered slide
--- costs its own keypress, because the image's fragment is the image and a block
--- cannot be appended to an inline.

-- Does the writer stage list items for us? With `incremental: false` nobody does.
local incremental_on = true
if PANDOC_WRITER_OPTIONS ~= nil and PANDOC_WRITER_OPTIONS.incremental ~= nil then
  incremental_on = PANDOC_WRITER_OPTIONS.incremental
end

-- Blocks that must not be staged. Speaker notes and slide chrome are not
-- content, and anything already carrying a fragment or staging class is the
-- author's call.
local passthrough = {
  fragment = true, notes = true, footer = true, aside = true, hidden = true,
  ["no-stage"] = true,
}

-- A `.together` div is one beat because the author said so, so it gets a wrapper
-- even when the list inside it would have staged itself; `solidify` turns that
-- list off. Every other container is judged by what is inside it and not by its
-- class name: see the NESTED STAGING note above.
--
-- This used to be an allowlist of seven container classes, which was the same rule
-- written the wrong way round. A div the list did not name, `.steps` being the one
-- that bit, got a wrapper around an already-staged list. The wrapper paints nothing
-- and `visibility: hidden` keeps the items' layout boxes, so the first press turned
-- an empty box visible and the slide did not move. Measured on the sample lecture:
-- two content slides, one dead press each.
local hand_grouped = { together = true }

-- Blocks that annotate the block above them and share its beat.
local addendum = {
  ["aside-note"] = true, citation = true, cite = true, caption = true,
  ["with-previous"] = true,
}

-- Passthrough blocks that are not content, so they must not break the chain
-- between a block and an addendum that follows it.
local invisible = { notes = true, footer = true, hidden = true }

-- Containers the filter cannot number around, because something else puts
-- unindexed fragments inside them.
local unnumberable = {
  fragment = true, ["quarto-layout-panel"] = true,
  ["r-stack"] = true, ["r-hstack"] = true, ["r-vstack"] = true,
  incremental = true,
}

local function classes_of(blk)
  if blk.t ~= "Div" and blk.t ~= "Span" then return {} end
  return blk.classes or {}
end

local function has_class(blk, set)
  for _, c in ipairs(classes_of(blk)) do
    if set[c] then return true end
  end
  return false
end

local function is_list(blk)
  return blk.t == "BulletList" or blk.t == "OrderedList" or blk.t == "DefinitionList"
end

-- A cell whose output Quarto will turn into a fragment of its own.
local function splits_into_fragment(blk)
  if blk.t ~= "Div" then return false end
  local where = (blk.attributes or {})["output-location"]
  return where ~= nil and where:match("fragment") ~= nil
end

-- A block that produces no visible output. Quarto appends one or two of these
-- at the end of a document, and staging one spends a keypress on nothing.
local function renders_nothing(blk)
  if blk.t == "Para" or blk.t == "Plain" then
    return #blk.content == 0
  elseif blk.t == "RawBlock" then
    return blk.text:match("^%s*$") ~= nil
  elseif blk.t == "Div" then
    if #blk.content == 0 then return true end
    for _, child in ipairs(blk.content) do
      if not renders_nothing(child) then return false end
    end
    return true
  end
  return false
end

-- Is the first visible thing inside this container already staged? A
-- `.fragment` child is the author's beat and a list is `incremental`'s.
local function insides_staged(blk)
  if blk.t ~= "Div" then return false end
  local stages_lists = incremental_on and not has_class(blk, { nonincremental = true })
  for _, child in ipairs(blk.content) do
    if not renders_nothing(child) then
      if has_class(child, { fragment = true }) then return true end
      if stages_lists and is_list(child) then return true end
      return false
    end
  end
  return false
end

-- ---- lone images ---------------------------------------------------------

-- Does this unit hold one image and nothing else visible? Quarto's auto-stretch
-- hoists such an image out to be a direct child of the section, so it is staged
-- in place instead of being wrapped. See the FIGURES note above for why anything
-- else in the unit disqualifies it.
--
-- Only a computed cell qualifies. A bare `![](fig.png)` is left to the wrapper,
-- because it has never been stretched under this filter and moving it onto
-- reveal's stretch path is a downgrade: reveal recomputes every
-- `section > .r-stretch` on every layout pass, `getRemainingHeight` restores an
-- invalid height when it is done measuring, and an image whose bytes have not
-- decoded yet measures as 0x0. The sharp edge is that reveal sizes each
-- `section > .r-stretch` on its own, as the canvas height minus the parent height
-- measured with that one element zeroed. A second stretched element in the same
-- section is therefore sized against a parent that still counts the first one,
-- and comes out starved. One stretched element per section is the only safe
-- arrangement, and hoisting bare images alongside a cell figure would put two
-- there. An earlier version of this note claimed the same 1400x1400 PNG measured
-- 559px after one layout pass and 14px after two; that does not reproduce, and
-- the two-stretch collision is the real failure. A cell figure is already on that
-- path today, so nothing changes for it.
local function lone_image(unit)
  if #unit ~= 1 then return nil end
  local blk = unit[1]
  if blk.t ~= "Div" or not has_class(blk, { cell = true }) then return nil end

  local images, blockers = 0, false
  pandoc.walk_block(blk, {
    Image = function() images = images + 1 end,
    -- A pandoc Figure carries a caption that auto-stretch moves out of reach.
    -- This branch never fires from a `.cell` div: Quarto builds a captioned cell
    -- figure as a custom AST node (`__quarto_custom_type = "FloatRefTarget"`),
    -- not a pandoc Figure. The Div arm of the emptiness walk below is what sees
    -- that node; it drops the whole node so the unit still reads as holding one
    -- image and nothing else, and the theme stages the hoisted caption off the
    -- image's own fragment state (`section > img.fragment + p.caption`). Kept for
    -- a pandoc Figure that arrives by some other route.
    Figure = function() blockers = true end,
    CodeBlock = function() blockers = true end,
    Table = function() blockers = true end,
    BulletList = function() blockers = true end,
    OrderedList = function() blockers = true end,
    DefinitionList = function() blockers = true end,
    BlockQuote = function() blockers = true end,
  })
  if images ~= 1 or blockers then return nil end

  -- Any text beside the image would be left behind by the hoist. Drop the
  -- images and see whether anything is left to read.
  local rest = pandoc.walk_block(blk, {
    Image = function() return {} end,
    Div = function(d)
      if d.attributes["__quarto_custom_type"] == "FloatRefTarget" then return {} end
    end,
  })
  if pandoc.utils.stringify(rest):match("^%s*$") == nil then return nil end
  return true
end

-- Put the beat on the image itself.
local function stage_image(blk, index)
  return pandoc.walk_block(blk, {
    Image = function(img)
      img.classes:insert("fragment")
      if index then img.attributes["fragment-index"] = tostring(index) end
      return img
    end,
  })
end

-- ---- raw HTML runs -------------------------------------------------------

local void_html = {
  area = true, base = true, br = true, col = true, embed = true, hr = true,
  img = true, input = true, link = true, meta = true, param = true,
  source = true, track = true, wbr = true,
}

-- Net change in HTML nesting depth contributed by one raw block. Comments,
-- doctypes, processing instructions, void elements, and self-closing tags all
-- count as zero.
local function depth_delta(s)
  local d = 0
  for tag in s:gmatch("<[^>]*>") do
    if not tag:match("^<!") and not tag:match("^<%?") then
      local closing = tag:match("^</%s*([%a][%w%-]*)")
      if closing then
        d = d - 1
      else
        local opening = tag:match("^<%s*([%a][%w%-]*)")
        if opening and not void_html[opening:lower()] and not tag:match("/%s*>%s*$") then
          d = d + 1
        end
      end
    end
  end
  return d
end

-- Raw HTML that carries no visible content, so staging it would spend a
-- keypress on nothing.
local function is_html_chrome(s)
  local name = s:match("^%s*<%s*([%a][%w%-]*)")
  if not name then return true end
  name = name:lower()
  return name == "style" or name == "script" or name == "template"
    or name == "noscript" or name == "link" or name == "meta"
end

-- Split a slide body into units. A unit is normally one block; a run of raw
-- HTML that opens a container is one unit spanning the whole container.
local function units_of(blocks)
  local units, i = {}, 1
  while i <= #blocks do
    local blk = blocks[i]
    if blk.t == "RawBlock" and depth_delta(blk.text) > 0 then
      local depth = depth_delta(blk.text)
      local run = { blk }
      i = i + 1
      while i <= #blocks and depth > 0 do
        local nxt = blocks[i]
        table.insert(run, nxt)
        if nxt.t == "RawBlock" then depth = depth + depth_delta(nxt.text) end
        i = i + 1
      end
      table.insert(units, run)
    else
      table.insert(units, { blk })
      i = i + 1
    end
  end
  return units
end

-- ---- can this slide's beats be numbered? --------------------------------

local function scan_blocks(blocks, state)
  for _, blk in ipairs(blocks) do
    if state.hit then return end
    if is_list(blk) and incremental_on then
      state.hit = true
    elseif blk.t == "Div" then
      local descend = true
      for _, c in ipairs(blk.classes or {}) do
        if unnumberable[c] then state.hit = true end
        -- A list inside either of these is not staged, so it cannot collide.
        if c == "nonincremental" or c == "together" then descend = false end
      end
      if splits_into_fragment(blk) then state.hit = true end
      if not state.hit and descend then scan_blocks(blk.content, state) end
    end
  end
end

local function numberable(blocks)
  local state = { hit = false }
  scan_blocks(blocks, state)
  if state.hit then return false end
  -- An inline `[x]{.fragment}` is unindexed too, and can sit anywhere.
  pandoc.walk_block(pandoc.Div(blocks), {
    Span = function(sp)
      for _, c in ipairs(sp.classes or {}) do
        if c == "fragment" then state.hit = true end
      end
    end,
  })
  return not state.hit
end

-- ---- staging ------------------------------------------------------------

local function beat(blocks, index)
  local attrs = {}
  if index then attrs = { { "fragment-index", tostring(index) } } end
  return pandoc.Div(blocks, pandoc.Attr("", { "fragment" }, attrs))
end

-- Append a block to a container already emitted, so both arrive on one beat.
local function append_to(container, blk)
  local content = container.content
  content:insert(blk)
  container.content = content
end

-- Append a block to the last item of a list, so it arrives with that item.
local function append_to_last_item(list, blk)
  local items = list.content
  if #items == 0 then return false end
  local item = items[#items]
  item:insert(blk)
  items[#items] = item
  list.content = items
  return true
end

-- A `.together` div is one beat, so a list inside it must not re-stage itself.
local function solidify(div)
  return pandoc.walk_block(div, {
    Blocks = function(blocks)
      local changed, out = false, {}
      for _, blk in ipairs(blocks) do
        if is_list(blk) then
          table.insert(out, pandoc.Div({ blk }, pandoc.Attr("", { "nonincremental" })))
          changed = true
        else
          table.insert(out, blk)
        end
      end
      if changed then return out end
    end,
  })
end

local function stage(body)
  local use_index = numberable(body)
  local out = {}
  local next_index = 0
  local open_index = nil   -- index of the beat most recently opened
  local prev = nil         -- { kind = "beat"|"image"|"list", node = ... }

  -- One beat, whether it is a wrapper div or a class on an image.
  local function open_beat(content)
    local index = use_index and next_index or nil
    local img = lone_image(content)
    if img then
      table.insert(out, stage_image(content[1], index))
      prev = { kind = "image" }
    else
      local div = beat(content, index)
      table.insert(out, div)
      prev = { kind = "beat", node = div }
    end
    open_index = next_index
    next_index = next_index + 1
  end

  -- Put a block on the beat above it. False when there is no way to.
  local function join_beat(blk)
    if prev.kind == "list" then return append_to_last_item(prev.node, blk) end
    if use_index and open_index then
      table.insert(out, beat({ blk }, open_index))
      return true
    end
    if prev.kind == "beat" then
      append_to(prev.node, blk)
      return true
    end
    return false
  end

  for _, unit in ipairs(units_of(body)) do
    local blk = unit[1]
    local single = #unit == 1

    if single and renders_nothing(blk) then
      table.insert(out, blk)

    elseif single and prev ~= nil and has_class(blk, addendum) then
      if not join_beat(blk) then open_beat({ blk }) end

    elseif single and has_class(blk, invisible) then
      table.insert(out, blk)

    elseif single and has_class(blk, passthrough) then
      table.insert(out, blk)
      -- Your own `.fragment` is a beat, so an addendum can join it.
      if has_class(blk, { fragment = true }) then
        prev = { kind = "beat", node = blk }
      else
        prev = nil
      end

    elseif single and not has_class(blk, hand_grouped) and insides_staged(blk) then
      table.insert(out, blk)
      prev = nil

    elseif single and is_list(blk) and incremental_on then
      table.insert(out, blk)
      prev = { kind = "list", node = blk }

    elseif blk.t == "RawBlock" and is_html_chrome(blk.text) then
      -- Raw HTML with nothing visible in it, and runs that open with style or
      -- script. Staging one would spend a keypress on nothing.
      for _, b in ipairs(unit) do table.insert(out, b) end

    else
      local content = unit
      if single and blk.t == "Div" and has_class(blk, { together = true }) then
        content = { solidify(blk) }
      end
      open_beat(content)
    end
  end

  return out
end

-- ---- jump buttons -------------------------------------------------------

-- Beamer's \hyperlink + \beamerbutton, in two words of markdown:
--
--   On a main slide:      Robustness is in the [appendix]{.jump target="ap-window"}.
--   On the appendix slide: [Back to the result]{.jump-back}, or bare []{.jump-back}
--
-- The span becomes a real `<a>`, not a raw HTML button, so it is focusable and it
-- still navigates if the script below never runs. Four details are deliberate:
--
--   * The href is the plain `#ap-window`, not reveal's documented `#/ap-window`.
--     Quarto rewrites a fragment href for the revealjs writer by inserting the
--     slash itself, so emitting the documented form produces `#//ap-window`,
--     which reveal parses as an empty name and resolves to the title slide.
--     Verified in the rendered deck. The plain form is also what reveal's own
--     hash parser wants: `getIndicesFromHash` strips `#` plus an OPTIONAL slash
--     (`/^#\/?/`), so both spellings resolve once the extra slash is gone
--     (hakimel's own instruction in reveal.js#55 is the slash-free one).
--   * `target=` is NOT copied onto the anchor. `target` is a real attribute on
--     `<a>`, so an anchor carrying it would open the appendix slide in a new
--     browsing context named after the slide the one time a click got past the
--     handler. It is rewritten to `data-jump`.
--   * `.jump-back` gets no target at all. There is one stored origin per deck and
--     any back button returns to it, so the same button works whichever appendix
--     slide the presenter has wandered onto.
--   * `.jump-back` with nothing in the span gets the word "Back". A return button
--     has one job and the label is the same on every one of them.
--
-- Two ways to make a target unreachable, both silent, both reveal's doing:
-- an all-digits id (`{#2024}`) is parsed as a slide index rather than a name, and
-- a `{visibility="hidden"}` slide is deleted from the DOM at init.
local wants_jump = false

-- Rebuild the span's attributes as an anchor's, dropping the two the filter
-- consumes and keeping anything else the author put there.
local function jump_attr(sp, extra_classes, extra_attrs)
  local classes = {}
  for _, c in ipairs(extra_classes) do table.insert(classes, c) end
  for _, c in ipairs(sp.classes or {}) do
    if c ~= "jump" and c ~= "jump-back" then table.insert(classes, c) end
  end
  local attrs = {}
  for _, kv in ipairs(extra_attrs) do table.insert(attrs, kv) end
  for k, v in pairs(sp.attributes or {}) do
    if k ~= "target" and k ~= "to" then table.insert(attrs, { k, v }) end
  end
  return pandoc.Attr(sp.identifier or "", classes, attrs)
end

function Span(sp)
  local jump, back = false, false
  for _, c in ipairs(sp.classes or {}) do
    if c == "jump" then jump = true elseif c == "jump-back" then back = true end
  end
  if not jump and not back then return nil end

  if back then
    wants_jump = true
    -- `[]{.jump-back}` gets the word "Back". That is the label the author's Beamer
    -- decks give every return button, fifteen of them, and a return button has one
    -- job, so writing the word out on each one is a chore with no decision in it.
    -- Any content in the span still wins.
    local label = sp.content
    if pandoc.utils.stringify(label):match("^%s*$") ~= nil then
      label = pandoc.Inlines({ pandoc.Str("Back") })
    end
    -- href="#" is never followed: the handler always preventDefaults. It is there
    -- so the button is a link the keyboard can reach.
    return pandoc.Link(label, "#", "",
      jump_attr(sp, { "jump-btn", "jump-back" }, { { "data-jump-back", "" } }))
  end

  local target = (sp.attributes or {})["target"] or (sp.attributes or {})["to"]
  if target then target = target:gsub("^#", "") end
  if not target or target == "" then
    io.stderr:write("stage-slide.lua: a [.jump] span has no target=, left as plain text\n")
    return sp.content
  end
  wants_jump = true
  return pandoc.Link(sp.content, "#" .. target, "",
    jump_attr(sp, { "jump-btn" }, { { "data-jump", target } }))
end

-- Storing the origin is the whole problem, and neither obvious answer works.
-- `Reveal.getPreviousSlide()` is the slide shown immediately before the current
-- one, so one arrow press after arriving in the appendix loses the way back. The
-- browser history is no better: Quarto sets `history: true`, so reveal writes an
-- entry per slide and Back walks the wander instead of undoing the jump. So the
-- jump records `Reveal.getState()` before it navigates and nothing but another
-- jump overwrites it.
--
-- `getState()` rather than `getIndices()` because it carries `indexf`, the
-- fragment step, and `setState()` feeds it straight back to `slide(h, v, f)`. It
-- also carries `paused` and `overview`, which is harmless: you cannot click a
-- button in either state, so both are false in anything we ever store. Note that
-- `getIndices(slide)` with an argument returns `f === undefined` by design, which
-- is why the forward jump computes the target's last step separately.
--
-- Beamer cannot do this half of it. Every one of its navigation macros,
-- `\hyperlinkappendixstart` included, expands to a compile-time page
-- destination, so `\beamerreturnbutton` has to name the origin overlay by hand
-- and one appendix slide cannot serve two callers. The published Quarto
-- equivalents (grantmcdermott/quarto-revealjs-clean and the themes that copied
-- its `.button` class) are static links back to a literal slide id for the same
-- reason.
local jump_script = [[
<script>
(function () {
  var origin = null;

  // The largest fragment step on a slide, in reveal's own group numbering:
  // an explicit data-fragment-index wins over DOM position, exactly as
  // Fragments.goto reads it.
  function lastStep(slide) {
    var frags = slide.querySelectorAll(".fragment"), last = -1;
    for (var i = 0; i < frags.length; i++) {
      var v = frags[i].hasAttribute("data-fragment-index")
        ? parseInt(frags[i].getAttribute("data-fragment-index"), 10) : i;
      if (v > last) last = v;
    }
    return last;
  }

  // PAST_MAIN
  // No stored origin, so the presenter walked into the appendix instead of
  // jumping. Hand back the last slide of the main deck, fully revealed.
  function lastMainSlide() {
    var slides = Reveal.getSlides();
    for (var i = 1; i < slides.length; i++) {
      if (pastMain(slides[i])) {
        var idx = Reveal.getIndices(slides[i - 1]);
        return { indexh: idx.h, indexv: idx.v, indexf: lastStep(slides[i - 1]) };
      }
    }
    return null;
  }

  // CAPTURE PHASE, and it has to be. reveal 5 binds its own click listener on the
  // `.slides` element (`onSlidesClicked`), which resolves any `a[href^="#"]`
  // through `getIndicesFromHash` and navigates. `.slides` is a descendant of
  // document, so it gets the bubbling click FIRST, and a document-level bubble
  // listener like the obvious version of this one records `Reveal.getState()`
  // AFTER reveal has already moved: the origin comes out as the appendix slide
  // and Back does nothing. Measured before the fix, jumping from slide 5: the
  // handler stored {indexh: 21, indexv: 0, indexf: -1}. Capturing on document
  // runs before every listener below it, and stopPropagation keeps reveal's
  // handler from firing at all, so the jump navigates exactly once.
  document.addEventListener("click", function (ev) {
    var a = ev.target && ev.target.closest ? ev.target.closest("a.jump-btn") : null;
    if (!a || !window.Reveal || !Reveal.isReady || !Reveal.isReady()) return;
    ev.stopPropagation();
    ev.preventDefault();

    if (a.hasAttribute("data-jump")) {
      var el = document.getElementById(a.getAttribute("data-jump"));
      // reveal resolves an id anywhere inside a slide, so match that: take the
      // section the id sits in rather than assuming the id is on the section.
      var sec = el && el.closest ? el.closest(".slides section") : null;
      if (!sec) return;
      origin = Reveal.getState();
      var to = Reveal.getIndices(sec);
      // Land it fully revealed. An appendix slide is a reference exhibit pulled
      // up under a question, and clicking through its staging in front of the
      // room is the wrong three keypresses.
      Reveal.slide(to.h, to.v, lastStep(sec));
    } else {
      var o = origin || lastMainSlide();
      if (o) Reveal.setState(o);
    }

    // Drop focus. A focused link eats the next Enter, and reveal ignores the
    // keyboard while focus is on an interactive element.
    if (a.blur) a.blur();
  }, true);
})();
</script>
]]

-- ---- citation hover target ----------------------------------------------
-- Quarto renders a narrative citation as
--   <span class="citation"><span class="nocase">Golder et al.</span> (<a>2023</a>)</span>
-- and its own bundled script binds the tippy popup with `tippyHover(citeInfo.el)`,
-- where `citeInfo.el` is the anchor its `findCites` walk started from. The anchor is
-- the year alone, so the entry only pops when the pointer is over four digits and the
-- author name, which is most of what the eye aims at, does nothing.
--
-- Retarget the existing instance instead of building a second one, so the popup keeps
-- Quarto's own content, placement, and theme. `triggerTarget` is tippy's supported way
-- to listen on one element and anchor to another.
--
-- A single-anchor span retargets to the whole span, as before. A multi-cite span
-- (`[@a; @b]` gives ONE span holding one anchor per work) cannot: retargeting the
-- first anchor to the span made hovering the second year fire two popups at once,
-- the second anchor's own plus the span-wide one. Such a span is segmented instead:
-- every text child is split at the `;` separators, each run between separators is
-- wrapped in a `span.cite-seg` (the leading parenthesis, the separators, and the
-- trailing parenthesis stay outside), and each anchor's tippy is retargeted to its
-- own wrapper. The content is narrowed too: Quarto's contentFn renders EVERY key in
-- the span's `data-cites` into one popup, which is right for a single-cite span and
-- wrong for a per-citation preview. The keys sit in `data-cites` in anchor order, so
-- anchor i takes key i; on a count mismatch or a missing entry the combined popup is
-- kept. The wrapper also carries the hover highlight: both themes cancel the
-- whole-span hover on `.cite-multi` and light `span.cite-seg:hover` instead.
--
-- On `load`, not `DOMContentLoaded`: Quarto attaches the instances from its own
-- DOMContentLoaded handler and this has to run after that one. The retries cover a
-- deck where the citation script is still resolving when `load` fires; each pass is a
-- no-op once `_tippy` is already retargeted, and segmentation runs once per span,
-- guarded by the `.cite-multi` class it stamps.
local cite_hover_script = [[
<script>
(function () {
  function segment(span) {
    var kids = Array.prototype.slice.call(span.childNodes), i, k, n, m;
    for (i = 0; i < kids.length; i++) {
      n = kids[i];
      if (n.nodeType === 3 && n.nodeValue.indexOf(";") !== -1) {
        var parts = n.nodeValue.split(/(;\s*)/);
        for (k = 0; k < parts.length; k++)
          if (parts[k]) span.insertBefore(document.createTextNode(parts[k]), n);
        span.removeChild(n);
      }
    }
    var runs = [], run = [];
    kids = Array.prototype.slice.call(span.childNodes);
    for (i = 0; i < kids.length; i++) {
      n = kids[i];
      if (n.nodeType === 3 && /^;\s*$/.test(n.nodeValue)) { runs.push(run); run = []; }
      else run.push(n);
    }
    runs.push(run);
    for (i = 0; i < runs.length; i++) {
      var g = runs[i];
      if (g.length && g[0].nodeType === 3) {
        m = g[0].nodeValue.match(/^([\s(]+)([\s\S]*)$/);
        if (m && !m[2]) g.shift();
        else if (m) { g[0].nodeValue = m[2]; span.insertBefore(document.createTextNode(m[1]), g[0]); }
      }
      if (g.length && g[g.length - 1].nodeType === 3) {
        var t = g[g.length - 1];
        m = t.nodeValue.match(/^([\s\S]*?)([\s)]+)$/);
        if (m && !m[1]) g.pop();
        else if (m) { t.nodeValue = m[1]; span.insertBefore(document.createTextNode(m[2]), t.nextSibling); }
      }
      if (!g.length) continue;
      var w = document.createElement("span");
      w.className = "cite-seg";
      span.insertBefore(w, g[0]);
      for (k = 0; k < g.length; k++) w.appendChild(g[k]);
    }
    span.classList.add("cite-multi");
  }
  function entryHTML(key) {
    var d = key && document.getElementById("ref-" + key);
    return d ? '<div class="hanging-indent csl-entry">' + d.innerHTML + "</div>" : "";
  }
  function retarget() {
    var spans = document.querySelectorAll("span.citation"), n = 0;
    for (var i = 0; i < spans.length; i++) {
      var as = spans[i].querySelectorAll('a[role="doc-biblioref"]');
      if (as.length < 2) {
        var a = spans[i].querySelector('a[role="doc-biblioref"]');
        if (a && a._tippy) { a._tippy.setProps({ triggerTarget: spans[i] }); n++; }
        continue;
      }
      if (!spans[i].classList.contains("cite-multi")) segment(spans[i]);
      var attr = spans[i].getAttribute("data-cites") || "";
      var keys = attr.replace(/^\s+|\s+$/g, "").split(/\s+/);
      var done = 0;
      for (var j = 0; j < as.length; j++) {
        if (!as[j]._tippy) continue;
        var seg = as[j].closest("span.cite-seg");
        var props = { triggerTarget: seg || spans[i] };
        if (keys.length === as.length) {
          var h = entryHTML(keys[j]);
          if (h) props.content = h;
        }
        as[j]._tippy.setProps(props);
        done++;
      }
      if (done === as.length) n++;
    }
    return n === spans.length;
  }
  window.addEventListener("load", function () {
    if (retarget()) return;
    var tries = 0;
    var t = setInterval(function () {
      if (retarget() || ++tries > 20) clearInterval(t);
    }, 100);
  });
})();
</script>
]]

-- ---- where the main deck ends -------------------------------------------

-- One predicate, spliced into both emitted scripts at their `// PAST_MAIN` line,
-- so the progress bar's denominator and a back button's fallback can never drift
-- apart. Its Lua twin is `leaves_main` in the document walk below.
--
-- Four classes, two boundaries. The appendix is the first, the references are the
-- second, and everything from whichever comes first is outside the main deck: not
-- in the denominator, given no segment, and on the far side of the line a back
-- button returns across. The bar reads 100% at the closing slide and stays there
-- through both, which is the honest reading. A twelve-slide appendix
-- plus three slides of references would otherwise leave the closing slide at
-- roughly half and tell the room the talk was nowhere near over, and a bar that
-- receded on entering either would be a worse lie than one that sat full.
local past_main_js = [[
  function pastMain(el) {
    var c = el.classList;
    return c.contains("appendix-break") || c.contains("appendix") ||
           c.contains("references-break") || c.contains("references");
  }
]]

local function splice_past_main(js)
  return (js:gsub("%s*//%s*PAST_MAIN", "\n" .. past_main_js))
end

-- The slide the argument ends on, named by the deck. A talk closes on the
-- titleless `.thanks-slide`; a lecture closes on a `.closing-slide`, which is a
-- real content slide with a heading (the reading and the homework for next time)
-- and is staged and gated like any other. Either one is the point where the
-- progress bar reads 100%.
--
-- Naming the slide rather than taking "whatever sits before the appendix" means a
-- slide added after the closing one cannot move the fill, and the closing slide
-- owns the last step of the bar outright. Its Lua twin is `is_closing` in the
-- document walk below.
local closing_js = [[
  function isClosing(el) {
    var c = el.classList;
    return c.contains("thanks-slide") || c.contains("closing-slide");
  }
]]

local function splice_closing(js)
  return (js:gsub("%s*//%s*CLOSING", "\n" .. closing_js))
end

-- ---- progress bar -------------------------------------------------------

-- Three jobs, all of which need reveal's own slide list.
--
-- Segments: reveal's progress bar is one element with an inner span whose width
-- it sets, so segmenting means drawing cuts over it. The cut positions are the
-- section dividers' share of the deck, which only reveal can count: it removes
-- `data-visibility="hidden"` slides from the DOM, counts the title slide, and
-- skips `.stack` wrappers. So the positions are read from `Reveal.getSlides()`
-- at run time and handed to CSS as custom properties. The theme draws them; a
-- theme with no rule for them is unaffected.
--
-- Denominator: the appendix is taken out of it, so the bar is full at the closing
-- slide and stays full through the appendix. reveal's `getProgress()` counts every
-- slide in the document and cannot be patched from here: its Progress controller
-- calls `this.Reveal.getProgress()` on the deck instance, and `window.Reveal` is a
-- copy of that instance's properties, so reassigning the method on the copy changes
-- nothing. Detaching the controller's span is what works. Its `scaleX` writes then
-- land on an element that is no longer in the document, and an identical clone in
-- its place picks up the same `.reveal .progress span` rule, transition included.
--
-- Slide number: the same `main` is the denominator the main body counts to, and
-- the appendix and the references restart at 1 and count to a denominator of their
-- own. See the slide-number note in the header for why the number comes from
-- reveal's `slideNumber` function hook and not from a second script writing the
-- element.
--
-- The fill, the cuts, and the number all run off the same `main`, so a divider's
-- cut sits exactly where the fill lands when the presenter reaches that divider and
-- the bar reads full on the slide numbered last. Check them together or not at all,
-- and check them settled: see the measuring note in the header.
local progress_script = splice_closing(splice_past_main([[
<script>
(function () {
  var bar = null;   // our fill span; reveal keeps writing to the one we detached
  var main = 0;     // slides up to and including the closing one, title included
  // PAST_MAIN
  // CLOSING
  function mainCount(slides) {
    var end = slides.length;
    for (var i = 0; i < slides.length; i++) {
      if (pastMain(slides[i])) { end = i; break; }
    }
    // A named closing slide ends the count where it sits. Searched backwards, so
    // the last one wins and anything the deck puts after it is already outside.
    for (var j = end - 1; j >= 1; j--) {
      if (isClosing(slides[j])) return j + 1;
    }
    return end;
  }

  function fill() {
    if (!bar) return;
    var slides = Reveal.getSlides();
    var cur = Reveal.getCurrentSlide();
    var i = slides.indexOf(cur);
    var last = main - 1;   // index of the closing slide
    var p;
    if (i < 0 || i >= last) {
      p = 1;   // the closing slide, or anywhere past it
    } else {
      var frags = cur.querySelectorAll(".fragment");
      var past = i;
      if (frags.length) {
        // reveal's own weighting, so a long staged slide still creeps forward.
        past += (cur.querySelectorAll(".fragment.visible").length / frags.length) * 0.9;
      }
      // The last step belongs to the closing slide. Without the cap, the slide one
      // press short of it reaches 0.9 of that step on its own fragments and reads
      // as full a slide early, which is the thing the closing slide is for.
      p = Math.min(past / last, (last - 1) / last);
    }
    bar.style.transform = "scaleX(" + p + ")";
  }

  // The number in the corner, cut at the same place the bar fills. The main body
  // counts to `main` and ends on the closing slide; the appendix and the references
  // restart at 1 and share one denominator, because they are one run of back
  // matter and not two.
  //
  // reveal takes `slideNumber` as a function returning [current, delimiter, total],
  // which is the array its own `c/t` branch builds, so `formatNumber` renders it
  // into the markup the themes already style. The total has to be a number: handed
  // a string, `formatNumber` drops the delimiter and the second span and prints the
  // current slide alone.
  function numbering(slides) {
    var tail = slides.length - main;
    if (tail < 1) return;   // nothing behind the argument, so c/t is already right
    // The list is read fresh on every call rather than closed over, so a sync that
    // rebuilt it cannot leave this indexing against a stale array. reveal hands back
    // a new array each time and the call is once per slide change.
    var fn = function (el) {
      var all = Reveal.getSlides();
      var i = all.indexOf(el || Reveal.getCurrentSlide());
      if (i < 0) return [1, "/", main];
      if (i < main) return [i + 1, "/", main];
      return [i - main + 1, "/", tail];
    };
    // `getConfig()` hands back the live config object, which the slide-number
    // controller reads through the same accessor, so assigning to it is enough and
    // costs none of `configure()`'s sync (a relayout, rebuilt backgrounds, rebound
    // listeners). The check is there because a reveal that returned a copy instead
    // would leave the old denominator standing with nothing else to show for it.
    Reveal.getConfig().slideNumber = fn;
    if (Reveal.getConfig().slideNumber === fn && Reveal.slideNumber
        && Reveal.slideNumber.update) {
      // First paint. reveal rendered the number once at init, off `c/t`, and
      // nothing asks it for another one until the first navigation.
      Reveal.slideNumber.update();
    } else {
      Reveal.configure({ slideNumber: fn });
    }
  }

  function setup() {
    if (!window.Reveal) return;
    var slides = Reveal.getSlides();
    if (slides.length < 2) return;
    main = mainCount(slides);
    if (main < 2) return;
    // Before the bar, and not gated on it: a deck rendered with `progress: false`
    // has no `.progress` element and still wants its number cut.
    numbering(slides);

    var prog = document.querySelector(".reveal .progress");
    if (!prog) return;

    // One cut per section divider, positioned against the main-content
    // denominator. A divider past the main deck gets none.
    var stops = [];
    for (var i = 1; i < main; i++) {
      if (slides[i].classList.contains("section-break")) {
        stops.push((100 * i / (main - 1)).toFixed(2) + "%");
      }
    }
    if (stops.length > 1) {
      prog.style.setProperty("--section-cuts", stops.length);
      stops.forEach(function (p, k) {
        prog.style.setProperty("--section-cut-" + (k + 1), p);
      });
      prog.classList.add("segmented");
    }

    // Nothing to take over when the deck ends with its argument and names no
    // closing slide: reveal's own denominator is already the right one. A named
    // closing slide is taken over even when it is the last slide in the deck,
    // because reveal has no notion of reserving the final step for it.
    if (main >= slides.length && !isClosing(slides[main - 1])) return;
    var theirs = prog.querySelector("span");
    if (!theirs) return;
    bar = theirs.cloneNode(false);
    prog.replaceChild(bar, theirs);
    prog.classList.add("metered");
    ["slidechanged", "fragmentshown", "fragmenthidden"].forEach(function (e) {
      Reveal.on(e, fill);
    });
    fill();

    // reveal's own click-to-seek maps the click across every slide in the deck,
    // which no longer matches what the bar draws. Capture on the ancestor, which
    // runs before the listener reveal bound on the bar itself.
    Reveal.getRevealElement().addEventListener("click", function (ev) {
      if (!ev.target || !ev.target.closest || !ev.target.closest(".progress")) return;
      ev.stopPropagation();
      ev.preventDefault();
      var w = Reveal.getRevealElement().offsetWidth || 1;
      var k = Math.round((ev.clientX / w) * (main - 1));
      k = Math.max(0, Math.min(main - 1, k));
      var to = Reveal.getIndices(Reveal.getSlides()[k]);
      Reveal.slide(to.h, to.v);
    }, true);
  }

  if (window.Reveal && Reveal.isReady && Reveal.isReady()) return setup();
  document.addEventListener("DOMContentLoaded", function () {
    var tries = 0;
    (function wait() {
      if (window.Reveal && Reveal.isReady && Reveal.isReady()) return setup();
      if (tries++ < 100) setTimeout(wait, 100);
    })();
  });
})();
</script>
]]))

-- ---- references: run citeproc, then paginate the list --------------------
--
-- THE PROBLEM. Quarto puts the whole bibliography in one `div#refs`, which for
-- anything past a handful of entries is taller than the 700px canvas. `quarto
-- render` exits 0 on it, so the failure is silent until the last slide of the
-- talk is a wall of overlapping text. Quarto's own answer is `handleRefs`, a DOM
-- pass that stamps `smaller scrollable` on whichever slide holds `#refs`, and
-- `.scrollable` is a defeat: it is a scroll box on a projector, it breaks
-- `auto-stretch`, and reveal's print view does not scroll, so it does not print.
-- `refs-location` is an HTML-format option and does nothing in revealjs. reveal
-- itself has no `allowframebreaks`. So the list has to be cut into slides here.
--
-- WHY CITEPROC RUNS FROM INSIDE THIS FILTER. Cutting the list needs the rendered
-- entries, and a user filter cannot see them: Quarto runs citeproc after its whole
-- Lua chain, including the `post-quarto` entry point (verified both ways, the
-- `#refs` div arrives with zero children at both). Listing `citeproc` in `filters:`
-- is a plain-pandoc feature that Quarto does not implement; it tries to exec a
-- binary of that name and dies with a FATAL error. So the filter calls
-- `pandoc.utils.citeproc(doc)` itself, and the deck turns pandoc's own run off:
--
--   bibliography: refs.bib
--   citeproc: false        # stage-slide.lua runs citeproc, so it can paginate
--
-- `citeproc: false` never reaches the filter (Quarto consumes it as a command-line
-- flag and strips it from the metadata), so this cannot be detected here. Forgetting
-- it means pandoc renders a second bibliography onto the last slide. That is caught
-- mechanically instead: the chunker leaves an EMPTY `#refs` behind, so a second run
-- fills that div rather than appending a new one, and `deck-check.mjs` fails a deck
-- whose `#refs` is not empty.
--
-- WHERE THE EMPTY `#refs` GOES, AND WHY IT MATTERS. Quarto's `handleRefs` finds
-- `#refs`, takes its slide's id, and points EVERY `a[role=doc-biblioref]` at that
-- slide; with no `#refs` in the document it sets every one of them to `href=""`
-- and `onclick="return false;"`, so dropping the id outright kills the citation
-- links. It also stamps `smaller scrollable` on that same slide. Both effects are
-- tied to one element, so the marker is parked on the `.references-break` DIVIDER:
-- the citation links then land on the "References" title slide, one press before
-- the list, which is the right destination for a list that paginates, and the two
-- unwanted classes land on a slide holding one word that both themes neutralise.
-- With no divider in the deck the marker stays on the first list page and the
-- themes neutralise the classes there instead.
--
-- HOW MANY ENTRIES FIT. Measured in headless Chrome at 1050x700, not guessed. The
-- packer works in rendered LINES, because entries are not the same height: in the
-- sample decks they run to two lines or three, and a longer one would run to four.
-- Two entries on the same page are separated by `margin-bottom` 0.62em over
-- `line-height` 1.35em, which is 0.46 of a line. Both themes set the same two ems,
-- so both give the same 0.46 (11.16px on the talk, 12.648px on the lecture).
--
-- The gap goes BETWEEN entries, so a page of n entries pays n-1 of them. The margin
-- under the last entry is not rendered: a block container's height stops at its
-- last child's border box. Measured on the talk, page one of the list, the bib body
-- runs 456px and its last entry ends at 456px with an 11.16px margin hanging off
-- the end that nothing counts. An earlier version charged every entry a gap, which
-- threw away half a line per page.
local refs_gap = 0.46

-- MEASURED in headless Chrome, per theme, with `offsetHeight` and not
-- `getBoundingClientRect`: reveal scales the whole canvas with a CSS transform,
-- so in the 1050x700 window `deck-check.mjs` opens, the 1050x700 canvas is drawn
-- at 0.9 and every rect comes back multiplied by it. A two-line talk entry
-- measures 43.9px that way instead of its layout 48.7px. The factor is invisible
-- until the arithmetic stops working.
--
--   talk     root 30px, entry 18.0px, line-height 24.3px, gap 11.16px, and the
--            first entry's box starts at y=75, so 625px of the 700px canvas is
--            left, which is 25.72 lines
--   lecture  root 34px, entry 20.4px, line-height 27.54px, gap 12.648px, and the
--            list starts at y=76, so 624px is left, which is 22.66 lines
--   starter  root 30px, entry 18.0px, line-height 24.3px, gap 11.16px, and the
--            list starts at y=70 under this theme's h2, so 630px is left,
--            which is 25.93 lines; both example decks measure identically,
--            because they share the one theme
--
-- THE BUDGETS ARE THOSE NUMBERS AND NOTHING ELSE. An earlier pair took about 45px
-- off each as clearance over the slide number and the progress bar, and that
-- clearance bought nothing: both sit OUTSIDE the canvas. reveal scales the 1050x700
-- box by 0.9 and centres it in the window, and the chrome is drawn in the margin
-- around it. Measured in canvas coordinates on a references slide of either deck,
-- the slide number's box starts at y=698.9 and runs to 727.8, and the progress bar
-- spans y=734.4 to 738.9. Nothing the list does inside 700px reaches either. That
-- margin on its own was costing the talk's page one an entry, and the old
-- characters-per-line figure cost it a second.
--
-- CHARACTERS PER LINE is bracketed and not averaged, because what matters is where
-- an entry gains a line. Counted in codepoints, the talk's longest two-line entry
-- ran 246 characters and its shortest three-line one 252; on the lecture the same
-- pair was 222 and 235. Read through the wrap model below, that puts the talk's
-- first line between 124.6 and 127.7 characters and the lecture's between 112.6 and
-- 119.2. Both presets sit at the low end of their bracket, so the model rounds a
-- line up before it rounds one down. At these values it predicts all 25 rendered
-- entries across the two decks exactly, 29 lines against 29 on each deck. The
-- lecture root is 13% larger and its line holds only 10% fewer characters, because
-- Source Sans Pro is a narrower face than the system stack the talk resolves to and
-- gives most of the difference back.
--
-- The starter bracket, measured the same way on the two example decks in docs/:
-- the longest two-line entry runs 264 characters and the shortest three-line one
-- 277, so the first line sits between 133.7 and 140.3; the preset takes the low
-- end again, 134. Starter fits more characters than the talk preset at the same
-- 18px because its body face is Source Sans Pro, the narrower face the lecture
-- note above describes. At 134 the model predicts all 25 rendered entries across
-- the two decks exactly, 27 lines against 27 on the talk and 25 against 25 on
-- the lecture.
--
-- `hang` is what the hanging indent takes off every line after an entry's first, as
-- a fraction of the line. The rule is `padding-left: 1.5em; text-indent: -1.5em` on
-- an entry set at 0.6 of root across the full 1050px canvas, so the fraction is
-- 1.5 * 0.6 * root / 1050: 27px of 1050 on the talk and the starter, 30.6px on
-- the lecture. Another theme computes its own from that formula.
--
-- The deck names its preset, because the theme cannot be read from here. Quarto
-- compiles the SCSS into a temp bundle and rewrites the metadata to its hash before
-- any user filter runs (measured: `theme = quarto-760b0d5cd483963edc939aa138f6e90a`
-- on a deck whose front matter says `theme: [default, my-theme.scss]`), so there
-- is nothing left to sniff. In this repo the wiring is one line in the starter
-- extension's `_extension.yml`, `refs-fit: starter`, next to the theme it was
-- measured against; a deck on the starter format needs no refs line of its own,
-- and that yml line is the knob to move. `talk` and `lecture` are kept for the
-- research-talk and teaching-lecture skills' own themes (30px and 34px roots).
-- The default stays `lecture` because it is the tightest of the presets, so a
-- deck that names no preset gets a slide of under-filled references and never an
-- overflow. `refs-lines` and `refs-chars-per-line` override the preset outright,
-- which is what a restyled theme or a much larger entry font needs.
local refs_presets = {
  talk    = { lines = 25.7, cpl = 125, hang = 0.026 },
  lecture = { lines = 22.6, cpl = 113, hang = 0.029 },
  starter = { lines = 25.9, cpl = 134, hang = 0.026 },
}

local function refs_budget(meta)
  local b = refs_presets.lecture
  if meta["refs-fit"] then
    b = refs_presets[pandoc.utils.stringify(meta["refs-fit"])] or b
  end
  local lines, cpl, hang = b.lines, b.cpl, b.hang
  if meta["refs-lines"] then
    lines = tonumber(pandoc.utils.stringify(meta["refs-lines"])) or lines
  end
  if meta["refs-chars-per-line"] then
    cpl = tonumber(pandoc.utils.stringify(meta["refs-chars-per-line"])) or cpl
  end
  return lines, cpl, hang
end

-- Characters in one entry, counted as CODEPOINTS. `#` on a Lua string counts bytes,
-- and citeproc emits curly quotes and en dashes at three bytes each, so a byte count
-- reads an entry as about six characters longer than it is (measured on the talk's
-- first entry: 221 characters, 227 bytes). Wrapping follows glyphs, so codepoints
-- are what the model wants, and the six-byte inflation is the same size as the
-- hanging-indent correction below. `utf8.len` returns nil on a malformed string, and
-- the byte count is the right answer to fall back to there.
local function char_count(s)
  if utf8 and utf8.len then
    local n = utf8.len(s)
    if n then return n end
  end
  return #s
end

-- The rendered height of one entry, in lines, with the hanging indent modelled.
-- The first line of an entry starts on the text rail and gets the full measure;
-- every line after it is inset by 1.5em and holds `1 - hang` of that. Folding the
-- indent into a single averaged `cpl` instead, which is what an earlier version did,
-- is wrong in the direction that matters: the error grows with the number of
-- continuation lines, so it lands on exactly the long multi-author entries that
-- decide where a page ends.
local function entry_cost(blk, cpl, hang)
  local n = char_count(pandoc.utils.stringify(blk))
  if n <= cpl then return 1 end
  local wrapped = cpl * (1 - (hang or 0))
  if wrapped < 1 then wrapped = 1 end
  return 1 + math.ceil((n - cpl) / wrapped)
end

-- GREEDY. Put as many entries on a page as fit, start the next page, repeat. The
-- last page carries the remainder however short that leaves it.
--
-- This used to run a second pass over the same entries aimed at an even split
-- across the page count the first pass found, so that a 14-entry list came out 7
-- and 7 instead of 12 and 2. That is the wrong goal. A reference list is read off
-- the wall one page at a time and nobody compares the pages, so a balanced split
-- buys nothing and costs a page every time the remainder would have fitted. What
-- the author sees is page one stopping early with room under it.
--
-- Worth knowing if you are re-reading the old code: on both sample decks the
-- balancing pass was a no-op. The talk packed 7+6 and the lecture 6+6 under either
-- rule, because the old budget cut the page before the even-split target was
-- reached. The 6+6 looked like the signature of an even split and was not; the
-- whole shortfall was the budget.
local function paginate(entries, budget, cpl, hang)
  local pages, cur, used = {}, {}, 0
  for _, e in ipairs(entries) do
    local lines = entry_cost(e, cpl, hang)
    if #cur == 0 then
      used = lines
    elseif used + refs_gap + lines > budget then
      pages[#pages + 1] = cur
      cur = {}
      used = lines
    else
      used = used + refs_gap + lines
    end
    cur[#cur + 1] = e
  end
  if #cur > 0 then pages[#pages + 1] = cur end
  return pages
end

-- Is this the heading of the reference list, or of the divider that opens it?
local function is_references(hdr)
  for _, c in ipairs(hdr.classes or {}) do
    if c == "references" then return true end
  end
  return false
end

local function is_references_break(hdr)
  for _, c in ipairs(hdr.classes or {}) do
    if c == "references-break" then return true end
  end
  return false
end

-- Split a references slide's body into what comes before the list, the list, and
-- what comes after it. The tail is usually a `.aside-note` with a back button.
local function split_refs(body)
  local before, refs, after = {}, nil, {}
  for _, b in ipairs(body) do
    if refs == nil and b.t == "Div" and b.identifier == "refs" then
      refs = b
    elseif refs == nil then
      before[#before + 1] = b
    else
      after[#after + 1] = b
    end
  end
  return before, refs, after
end

-- ---- document walk -----------------------------------------------------

function Pandoc(doc)
  -- Citations first, before anything counts blocks or cuts the list. `citeproc:
  -- false` in the deck stops pandoc running it a second time; see the references
  -- note above for why it has to happen here and not in pandoc's own chain.
  local has_cite = false
  doc.blocks:walk({ Cite = function() has_cite = true end })
  local has_bib = doc.meta.bibliography ~= nil or doc.meta.references ~= nil
  if has_bib and has_cite then
    local ok, done = pcall(pandoc.utils.citeproc, doc)
    if ok then
      doc = done
    else
      io.stderr:write("stage-slide.lua: citeproc failed, citations left raw: "
        .. tostring(done) .. "\n")
    end
  end

  local out = {}
  local header = nil
  local body = {}
  local sections = 0

  local function is_divider(hdr)
    for _, c in ipairs(hdr.classes or {}) do
      if c == "section-break" then return true end
    end
    return false
  end

  -- Where the main deck ends. The appendix and the references are both outside
  -- it, for the progress bar and for a back button, and this is the one Lua-side
  -- predicate that says so. Its JavaScript twin is `pastMain` below, spliced into
  -- both emitted scripts.
  local function leaves_main(hdr)
    for _, c in ipairs(hdr.classes or {}) do
      if c == "appendix-break" or c == "appendix"
        or c == "references-break" or c == "references" then return true end
    end
    return false
  end

  -- Where the argument ends. The JavaScript twin is `isClosing`, spliced into the
  -- progress script. A deck that names a closing slide needs that script even with
  -- one section divider and no appendix, because reveal alone will not hold the
  -- last step of the bar for it.
  local function is_closing(hdr)
    for _, c in ipairs(hdr.classes or {}) do
      if c == "thanks-slide" or c == "closing-slide" then return true end
    end
    return false
  end

  -- Total first, in its own pass: the first divider needs a number that only
  -- the last divider establishes. The same pass answers whether the deck has
  -- anything past the main content, which decides whether the progress script has
  -- work to do even in a deck with one section or none.
  local total = 0
  local has_tail = false
  local has_closing = false
  local has_refs = false      -- a `#refs` div citeproc actually filled
  for _, blk in ipairs(doc.blocks) do
    if blk.t == "Header" then
      if is_divider(blk) then total = total + 1 end
      if leaves_main(blk) then has_tail = true end
      if is_closing(blk) then has_closing = true end
    elseif blk.t == "Div" and blk.identifier == "refs" and #blk.content > 0 then
      has_refs = true
    end
  end
  if has_cite and has_bib and not has_refs then
    io.stderr:write("stage-slide.lua: this deck cites but has no reference list. "
      .. "Add a `## References {.references}` slide holding `::: {#refs}`, or the "
      .. "citation links will not resolve.\n")
  end
  -- The empty `#refs` marker goes on the divider when there is one, so Quarto's
  -- `smaller scrollable` and its citation-link target both land on a slide holding
  -- one word. Otherwise it goes at the top of the first list page.
  local marker_placed = false
  local function refs_marker()
    marker_placed = true
    return pandoc.Div({}, pandoc.Attr("refs", {}, {}))
  end

  -- Number the section dividers in document order. See the counter note above.
  local function number_divider(hdr)
    if not is_divider(hdr) then return end
    sections = sections + 1
    hdr.attributes["data-section-number"] = tostring(sections)
    hdr.attributes["data-section-total"] = tostring(total)
  end

  -- A level-2 or deeper header opens a content slide. A level-1 header is a
  -- section divider carrying only its own title, so there is nothing to stage.
  -- A references slide is never staged. There is no argument being built, and
  -- clicking through a reference list one entry at a time in front of a room is
  -- the wrong eight keypresses. That covers the whole slide, including a back
  -- button in a trailing `.aside-note`.
  local function staged(hdr)
    if not hdr or hdr.level < 2 then return false end
    for _, c in ipairs(hdr.classes or {}) do
      if c == "no-stage" or c == "references" then return false end
    end
    return true
  end

  -- Cut the reference list across as many slides as it needs, each one a copy of
  -- the references heading. Blocks the author put before the list stay on page one
  -- and blocks after it go to the last page, which is where a back button belongs.
  local function emit_references()
    local before, refs, after = split_refs(body)
    if not refs then
      table.insert(out, header)
      for _, blk in ipairs(body) do table.insert(out, blk) end
      return
    end
    local budget, cpl, hang = refs_budget(doc.meta)
    local pages = paginate(refs.content, budget, cpl, hang)
    -- `STAGE_REFS_DEBUG=1 quarto render deck.qmd` prints what the packer decided,
    -- which is the only way to retune the budget without reading minds. It reports
    -- the fill each page reached against the budget, so a page that stopped a long
    -- way short says whether the model or the ordering is responsible.
    if os.getenv("STAGE_REFS_DEBUG") then
      local sizes, fills = {}, {}
      for _, pg in ipairs(pages) do
        sizes[#sizes + 1] = tostring(#pg)
        local used = 0
        for k, e in ipairs(pg) do
          used = used + entry_cost(e, cpl, hang) + (k > 1 and refs_gap or 0)
        end
        fills[#fills + 1] = ("%.2f"):format(used)
      end
      io.stderr:write(("stage-slide.lua refs: %d entries, budget %.2f lines at %d "
        .. "chars/line, hang %.3f, pages of %s, filled to %s\n"):format(
        #refs.content, budget, cpl, hang or 0, table.concat(sizes, "+"),
        table.concat(fills, "+")))
      for _, e in ipairs(refs.content) do
        io.stderr:write(("  chars=%3d lines=%d\n"):format(
          char_count(pandoc.utils.stringify(e)), entry_cost(e, cpl, hang)))
      end
    end
    local base = header.identifier
    if base == "" then base = "references" end
    for k, entries in ipairs(pages) do
      local hdr = (k == 1) and header or header:clone()
      if k > 1 then hdr.identifier = base .. "-p" .. k end
      -- Written and drawn by neither theme, exactly like `data-section-total`: the
      -- slide number in the corner already says which page of the list this is, and
      -- a "cont." marker in the heading would be a third locator next to that and
      -- the standing REFERENCES pill. Kept on the heading so a theme can want it.
      hdr.attributes["data-refs-page"] = tostring(k)
      hdr.attributes["data-refs-pages"] = tostring(#pages)
      table.insert(out, hdr)
      if k == 1 then
        if not marker_placed then table.insert(out, refs_marker()) end
        for _, blk in ipairs(before) do table.insert(out, blk) end
      end
      -- A fresh class list and attribute table per page, and no identifier: two
      -- pages carrying `#refs` would be a duplicate id, and `handleRefs` would pick
      -- whichever came first and stamp it `scrollable`.
      local classes = {}
      for _, c in ipairs(refs.classes) do classes[#classes + 1] = c end
      local attrs = {}
      for k2, v in pairs(refs.attributes) do attrs[k2] = v end
      table.insert(out, pandoc.Div(entries, pandoc.Attr("", classes, attrs)))
      if k == #pages then
        for _, blk in ipairs(after) do table.insert(out, blk) end
      end
    end
  end

  local function flush()
    if header and is_references(header) then
      emit_references()
      body = {}
      return
    end
    if header then table.insert(out, header) end
    if header and is_references_break(header) and has_refs and not marker_placed then
      table.insert(out, refs_marker())
    end
    if staged(header) then
      for _, blk in ipairs(stage(body)) do table.insert(out, blk) end
    else
      for _, blk in ipairs(body) do table.insert(out, blk) end
    end
    body = {}
  end

  for _, blk in ipairs(doc.blocks) do
    if blk.t == "Header" then
      flush()
      number_divider(blk)
      header = blk
    else
      table.insert(body, blk)
    end
  end
  flush()

  -- Two dividers is the floor for drawing cuts; an appendix, a references section,
  -- or a named closing slide is enough on its own to need the denominator
  -- rewritten.
  if total > 1 or has_tail or has_closing then
    table.insert(out, pandoc.RawBlock("html", progress_script))
  end
  if wants_jump then
    table.insert(out, pandoc.RawBlock("html", jump_script))
  end
  -- Unconditional. It walks `span.citation` and does nothing on a deck that cites
  -- nothing, and gating it on the reference machinery would miss a deck that cites
  -- works without paginating a list.
  table.insert(out, pandoc.RawBlock("html", cite_hover_script))

  return pandoc.Pandoc(out, doc.meta)
end
