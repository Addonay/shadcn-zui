# shadcn-zui full component plan

Goal: one catalog that merges the component inventories of the libraries we
mirror, then implement every entry that can exist in a Zig UI framework.

Sources surveyed (2026-09-16):

- **gpui-kit** (gpui-kit.com/component, + local clone in `.references/gpui-kit/`)
  — the structural reference we follow (Rust/GPUI).
- **shadcn/ui** (ui.shadcn.com/docs/components) — the styling reference.
- **HeroUI** (formerly NextUI, heroui.com) — adds pickers, listbox, meter,
  progress circle, toolbar, disclosure.
- **Mantine** (mantine.dev) — adds timeline, tree, transfer, rating, ring
  progress, indicator, spotlight, notification, highlight, code highlight,
  image, carousel, chip, segmented, password input, pin input, stat.
- **Ant Design** — adds statistic, result, watermark, tour, timeline, tree,
  transfer, segmented, cascader, comment, qr code.
- **MUI / daisyUI / PrimeReact / Fluent** — fab, speed dial, app bar,
  speedometer, org chart (covered by the same primitives below).
- **TanStack Charts** (tanstack.com/charts), **d3**, **Apache ECharts**,
  **Recharts** — chart grammars and chart type catalogs (sources downloaded
  into `.references/charting/`).
- **Icon sets**: Lucide (bundled), Tabler, Phosphor, Heroicons, HugeIcons,
  Remix — as swappable icon presets.

Status legend: ✅ exists · 🆕 new in this wave · ⏭️ deferred (framework-level,
with reason) · 🧩 covered by (component that already fulfills the role).

## 1. Components — merged master list

### Basic / display

| #   | Component                                     | Sources                     | Status | Notes                                       |
| --- | --------------------------------------------- | --------------------------- | ------ | ------------------------------------------- |
| 1   | Button                                        | all                         | ✅     | variants, sizes, icons                      |
| 2   | IconButton / ActionIcon                       | gpui-kit, Mantine, MUI      | ✅     |                                             |
| 3   | DropdownButton                                | gpui-kit                    | 🆕     | button that opens a dropdown menu           |
| 4   | ButtonGroup                                   | shadcn, HeroUI              | ✅     |                                             |
| 5   | Toggle / ToggleGroup                          | shadcn, MUI                 | ✅     |                                             |
| 6   | Segmented control                             | Ant, Mantine                | 🆕     | pill variant of ToggleGroup                 |
| 7   | FAB (floating action button)                  | MUI                         | 🆕     | fixed-position round button                 |
| 8   | Badge / Indicator                             | all                         | ✅     | + dot indicator preset 🆕                   |
| 9   | Tag / Chip                                    | Ant, Mantine, gpui-kit      | 🆕     | closable category label                     |
| 10  | Card                                          | all                         | ✅     | + metric card                               |
| 11  | GroupBox                                      | gpui-kit                    | ✅     |                                             |
| 12  | Item (media/content/actions)                  | shadcn                      | 🆕     | list row scaffolding                        |
| 13  | DescriptionList                               | gpui-kit                    | ✅     |                                             |
| 14  | Statistic / Stat                              | Ant, Mantine                | 🆕     | big value + label + delta                   |
| 15  | Image                                         | gpui-kit, Mantine           | 🆕     | wrapper over `zui.img()`                    |
| 16  | AspectRatio                                   | shadcn                      | 🆕     | ratio-constrained box                       |
| 17  | Avatar / AvatarGroup                          | all                         | ✅     |                                             |
| 18  | Icon                                          | all                         | ✅     |                                             |
| 19  | Kbd                                           | all                         | ✅     |                                             |
| 20  | Label                                         | all                         | ✅     |                                             |
| 21  | Link                                          | all                         | ✅     |                                             |
| 22  | Typography presets                            | shadcn, Mantine             | 🆕     | h1..h4, muted text, blockquote, code        |
| 23  | Code                                          | Mantine                     | 🆕     | monospace inline/block                      |
| 24  | Highlight                                     | Mantine, TanStack Highlight | 🆕     | marked-substring text                       |
| 25  | Marker                                        | gpui-kit, shadcn            | 🆕     | status dot + divider marker                 |
| 26  | Attachment                                    | gpui-kit, shadcn            | 🆕     | file chip: icon, name, size, remove         |
| 27  | Empty                                         | shadcn, gpui-kit            | ✅     |                                             |
| 28  | Result                                        | Ant                         | 🆕     | status icon + title + description + actions |
| 29  | Timeline                                      | Ant, Mantine                | 🆕     | vertical dot/line steps                     |
| 30  | Comment                                       | Ant                         | 🆕     | avatar + content + actions row              |
| 31  | List / ListBox                                | gpui-kit, HeroUI            | 🆕     | selectable item list (popover-ready)        |
| 32  | Carousel                                      | gpui-kit, Mantine           | 🆕     | paged strip with arrows + dots              |
| 33  | Timeline (message) — Message, MessageScroller | gpui-kit                    | 🆕     | chat message block + list                   |
| 34  | Bubble                                        | gpui-kit, shadcn            | 🆕     | chat bubble with alignment                  |
| 35  | Watermark                                     | Ant                         | 🆕     | diagonal repeating text overlay             |
| 36  | Timeline — see 29                             |                             |        |                                             |
| 37  | Tree                                          | gpui-kit, Ant, Mantine      | 🆕     | expandable hierarchy                        |
| 38  | Transfer                                      | Ant, Mantine                | 🆕     | two lists with move controls                |
| 39  | Stepper / Steps                               | gpui-kit, Ant               | ✅     |                                             |
| 40  | Timeline (horizontal)                         | —                           | 🆕     | compact horizontal stepper variant          |
| 41  | Timeline markers in Table row                 | —                           | ⏭️     | niche; not planned                          |

### Form / input

| #   | Component                       | Sources                   | Status  | Notes                                      |
| --- | ------------------------------- | ------------------------- | ------- | ------------------------------------------ |
| 42  | Input                           | all                       | ✅      | presentation chrome                        |
| 43  | Textarea                        | all                       | ✅      |                                            |
| 44  | InputGroup                      | shadcn, HeroUI            | 🆕      | input with leading/trailing addons         |
| 45  | SearchField                     | HeroUI                    | 🆕      | input + clear + kbd hint                   |
| 46  | PasswordInput                   | Mantine                   | 🆕      | input + reveal toggle                      |
| 47  | NumberInput                     | gpui-kit, Mantine, Ant    | 🆕      | value stepper with +/- buttons             |
| 48  | Select                          | all                       | 🆕      | trigger + listbox popover                  |
| 49  | NativeSelect                    | shadcn                    | 🆕      | display-styled select look                 |
| 50  | Combobox                        | gpui-kit, shadcn, Mantine | 🆕      | filterable select                          |
| 51  | Autocomplete                    | Mantine, Ant, HeroUI      | 🆕      | free text + suggestions (Combobox variant) |
| 52  | MultiSelect                     | Mantine, Ant              | 🆕      | multi-select listbox w/ chips              |
| 53  | Checkbox / CheckboxGroup        | all                       | ✅ / 🆕 | group wrapper                              |
| 54  | Switch                          | all                       | ✅      |                                            |
| 55  | RadioGroup                      | all                       | ✅      |                                            |
| 56  | Slider                          | gpui-kit, shadcn          | ✅      | entity widget                              |
| 57  | Rating                          | gpui-kit, Ant, Mantine    | ✅      |                                            |
| 58  | DatePicker / Calendar           | gpui-kit, Ant, HeroUI     | 🆕      | month grid, pure date math                 |
| 59  | RangeCalendar / DateRangePicker | HeroUI                    | 🆕      | range variant                              |
| 60  | TimeField                       | HeroUI                    | 🆕      | hour/minute stepper field                  |
| 61  | OTPInput / PinInput             | shadcn, Mantine, gpui-kit | 🆕      | per-cell code input                        |
| 62  | ColorPicker / ColorField        | gpui-kit, Ant, Mantine    | 🆕      | swatch grid + hex field                    |
| 63  | FilePicker / Attachment picker  | gpui-kit                  | 🆕      | button + file chip list                    |
| 64  | Form / Field / Fieldset         | shadcn, HeroUI            | 🆕      | label + control + description + error      |
| 65  | Checkbox-card / Radio-card      | shadcn                    | 🆕      | card-styled choice                         |
| 66  | Mentions / RichTextEditor       | Ant, Mantine              | ⏭️      | needs text-model infra zui lacks           |
| 67  | Cascader                        | Ant                       | ⏭️      | needs hierarchical search infra            |
| 68  | TreeSelect                      | Ant                       | ⏭️      | needs Tree + Select composition first      |
| 69  | Cascader, Tour                  | Ant                       | ⏭️      | low value in this framework now            |

### Overlays

| #   | Component                       | Sources                   | Status | Notes                              |
| --- | ------------------------------- | ------------------------- | ------ | ---------------------------------- |
| 70  | Dialog / Modal                  | all                       | ✅     |                                    |
| 71  | AlertDialog                     | shadcn                    | ✅     |                                    |
| 72  | Sheet / Drawer                  | shadcn, HeroUI            | ✅     | sides right/left; bottom/top 🆕    |
| 73  | Popover                         | all                       | ✅     |                                    |
| 74  | HoverCard                       | shadcn, gpui-kit, Mantine | 🆕     | popover variant on hover           |
| 75  | DropdownMenu                    | shadcn                    | ✅     |                                    |
| 76  | ContextMenu                     | shadcn, gpui-kit          | 🆕     | menu at pointer                    |
| 77  | Menubar                         | shadcn                    | 🆕     | horizontal bar of menus            |
| 78  | NavigationMenu                  | shadcn                    | 🆕     | horizontal nav with panels         |
| 79  | Tooltip                         | all                       | ✅     |                                    |
| 80  | Toast / Notification / Snackbar | shadcn, Mantine           | ✅     |                                    |
| 81  | LoadingOverlay                  | Mantine                   | 🆕     | scrim + spinner overlay            |
| 82  | Image viewer / Lightbox         | Ant                       | ⏭️     | zoom/pan infra deferred            |
| 83  | FocusTrap                       | gpui-kit, shadcn          | ⏭️     | framework-level (zui focus system) |
| 84  | Root provider / Theme           | gpui-kit                  | ⏭️     | zui owns window/theme lifecycle    |

### Navigation

| #   | Component         | Sources        | Status | Notes                             |
| --- | ----------------- | -------------- | ------ | --------------------------------- |
| 85  | Tabs              | all            | ✅     |                                   |
| 86  | Breadcrumb        | shadcn, HeroUI | ✅     |                                   |
| 87  | Pagination        | all            | ✅     |                                   |
| 88  | Sidebar           | shadcn         | ✅     |                                   |
| 89  | NavLink           | Mantine        | 🆕     | sidebar-style link row            |
| 90  | Affix / BackTop   | Mantine, Ant   | 🆕     | fixed-position corner button      |
| 91  | StatusBar         | gpui-kit       | 🆕     | bottom bar with left/center/right |
| 92  | Anchor            | Mantine, Ant   | 🆕     | link variant with active state    |
| 93  | Menu (nav)        | gpui-kit       | ✅     | dropdown menu covers              |
| 94  | Dock              | gpui-kit       | ⏭️     | full window-management system     |
| 95  | AppShell / Layout | Mantine        | ⏭️     | composed from Sidebar + StatusBar |

### Feedback

| #   | Component                     | Sources                   | Status | Notes                           |
| --- | ----------------------------- | ------------------------- | ------ | ------------------------------- |
| 96  | Progress                      | all                       | ✅     | linear bar                      |
| 97  | ProgressCircle / RingProgress | HeroUI, Mantine           | 🆕     | radial SVG ring                 |
| 98  | Meter                         | HeroUI                    | 🆕     | labeled progress                |
| 99  | Spinner                       | all                       | ✅     |                                 |
| 100 | Shimmer                       | gpui-kit                  | 🆕     | pulse animation on any element  |
| 101 | Skeleton                      | all                       | ✅     |                                 |
| 102 | Alert                         | all                       | ✅     |                                 |
| 103 | Empty                         | all                       | ✅     |                                 |
| 104 | SkeletonGroup                 | HeroUI                    | 🆕     | stack of skeleton primitives    |
| 105 | Marker — see 25               |                           |        |                                 |
| 106 | ScrollShadow / ScrollArea     | HeroUI, gpui-kit          | ✅     | scroll area have; fade edges 🆕 |
| 107 | Spotlight / Command           | shadcn, Mantine, gpui-kit | ✅     | command palette                 |
| 108 | Questionnaire / Form flow     | shadcn                    | 🆕     | paged field list                |

### Chat (gpui-kit/shadcn new family)

| #   | Component              | Sources  | Status | Notes                               |
| --- | ---------------------- | -------- | ------ | ----------------------------------- |
| 109 | Bubble                 | gpui-kit | 🆕     |                                     |
| 110 | Message                | gpui-kit | 🆕     | role avatar + name + time + content |
| 111 | MessageScroller        | gpui-kit | 🆕     | tail-following message list         |
| 112 | Marker (chat) — see 25 |          |        |                                     |

### Resizable / misc framework pieces

| #   | Component               | Sources                    | Status     | Notes                               |
| --- | ----------------------- | -------------------------- | ---------- | ----------------------------------- |
| 113 | Resizable / Splitter    | shadcn, gpui-kit, Ant      | 🆕         | draggable horizontal split          |
| 114 | Scrollable              | gpui-kit                   | ✅         | zui scroll + ScrollArea             |
| 115 | VirtualList             | gpui-kit, TanStack Virtual | ⏭️         | needs zui virtualization infra      |
| 116 | Editor                  | gpui-kit                   | ⏭️         | needs zui text-model infra          |
| 117 | TextView (markdown)     | gpui-kit                   | 🆕(subset) | headings/lists/inline-code renderer |
| 118 | Image carousel — see 32 |                            |            |                                     |
| 119 | QRCode                  | Ant                        | ⏭️         | needs QR encoder; note as future    |
| 120 | Tour                    | Ant                        | ⏭️         | needs focus-follow infra            |

## 2. Charts

Chart engine: pure SVG builders writing into caller buffers (no allocation in
render), same as the existing AreaChart/BarChart/LineChart/PieChart. Chart
type catalogs mirrored from the references in `.references/charting/`:

| Chart                       | d3        | ECharts      | Recharts/shadcn | TanStack grammar | gpui-kit plot | Status                       |
| --------------------------- | --------- | ------------ | --------------- | ---------------- | ------------- | ---------------------------- |
| Line                        | ✓         | line         | LineChart       | point/line       | ✓             | ✅                           |
| Step line                   | curveStep | line-step    | —               | line-mark        | —             | 🆕                           |
| Area / stacked area         | curveArea | area/lines   | AreaChart       | area-mark        | ✓             | ✅                           |
| Bar / grouped               | bar       | bar          | BarChart        | rect-mark        | ✓             | ✅                           |
| Horizontal bar              | —         | bar yAxis    | —               | rect             | —             | 🆕                           |
| Stacked bar                 | —         | bar-stack    | —               | rect-stack       | —             | 🆕                           |
| Waterfall                   | —         | custom       | —               | rect             | —             | 🆕                           |
| Pie / Donut                 | arc       | pie          | PieChart        | arc              | ✓             | ✅                           |
| Radial bars / PolarArea     | —         | —            | RadialBar       | arc-stack        | —             | 🆕                           |
| Scatter                     | circle    | scatter      | ScatterChart    | point            | —             | 🆕                           |
| Bubble                      | —         | scatter size | —               | point-size       | —             | 🆕                           |
| Radar                       | radar     | radar        | RadarChart      | polar-line       | —             | 🆕                           |
| Gauge / speedometer         | —         | gauge        | RadialBar       | —                | —             | 🆕                           |
| Sparkline                   | —         | —            | mini line       | —                | —             | 🆕                           |
| Heatmap                     | —         | heatmap      | —               | rect-grid        | —             | 🆕                           |
| Treemap                     | treemap   | treemap      | —               | —                | —             | 🆕                           |
| Funnel                      | —         | funnel       | Funnel          | —                | —             | 🆕                           |
| Candlestick / OHLC          | —         | candlestick  | —               | —                | plot has it   | 🆕                           |
| Composed (bar + line)       | —         | —            | ComposedChart   | layered marks    | —             | 🆕                           |
| Sankey / Graph              | sankey    | sankey/graph | —               | —                | —             | ⏭️ phase 2 (layout-heavy)    |
| Sunburst                    | partition | sunburst     | —               | —                | —             | ⏭️ phase 2                   |
| Box plot                    | boxplot   | boxplot      | —               | —                | —             | ✅ BoxPlot               |
| Parallel / ThemeRiver / Map | —         | ✓            | —               | —                | —             | ⏭️ not applicable (geo/maps) |
| Calendar heatmap            | —         | calendar     | —               | —                | —             | 🆕                           |

Chart references downloaded into `.references/charting/`: `d3` (full bundle),
`apache-echarts`, `recharts` (shadcn's chart engine), `@tanstack/charts` —
used as the type/spec reference for the SVG builders above.

## 3. Icon presets

The icon component ships **lucide** by default (bundled, 1830 names).
An options preset selects the active icon family; only the active preset's
assets are compiled into the binary.

| Preset             | Package               | Count (approx)         | Style             |
| ------------------ | --------------------- | ---------------------- | ----------------- |
| `lucide` (default) | bundled from gpui-kit | 1830                   | stroke, 24px grid |
| `tabler`           | @tabler/icons         | ~1300 outline + filled | stroke            |
| `phosphor`         | @phosphor-icons/core  | ~900 regular           | stroke            |
| `heroicons`        | heroicons             | ~300                   | stroke + solid    |
| `hugeicons`        | @hugeicons/free       | ~400 free              | stroke            |

Design: `tools/gen_icons.py` gains `--preset` (generates `names_<preset>.zig`
and copies SVGs to `src/components/icon/assets/<preset>/`). The icon component
exposes `IconOptions = struct { preset: Preset = .lucide }`; `build.zig`
option `-Dicons-preset=tabler` feeds build options so apps opt in at build
time — the default build links only lucide assets.

## 4. Implementation status (2026-09-17)

Delivered:

- **Batch A** ✅ — AspectRatio, Item, Field, Tag, Timeline, Statistic,
  Result, Indicator, Comment, Watermark, Code, Highlight, NavLink,
  StatusBar, LoadingOverlay, Affix, Image, Shimmer, Marker, Attachment,
  Bubble, Message.
- **Batch B** ✅ — DropdownButton, ContextMenu, Menubar, NavigationMenu,
  HoverCard, List, Segmented, FAB (Sheet already covered Drawer on all four
  sides).
- **Batch C** ✅ — Calendar + RangeCalendar as entity widgets with pure
  civil-date math (leap years, weekdays, 42-cell Sunday grids, month
  arithmetic; 15 unit tests). DatePicker = Popover + Calendar (documented
  composition).
- **Batch D** ✅ — Select, Combobox, Autocomplete, MultiSelect,
  NumberInput, PasswordInput, SearchField, OTP/PinInput, ColorPicker,
  TimeField, InputGroup, ChoiceCard (checkbox/radio card), Field.
- **Batch E** ✅ — Tree, Transfer, Resizable, Carousel, TextView (block
  markdown subset), Questionnaire.
- **Batch F** ✅ — Scatter (+bubble), Radar, Gauge, Sparkline, Heatmap,
  Treemap, Funnel, Candlestick, Waterfall, StackedArea, StackedBar,
  HBar, Composed (13 new chart types over the existing Area/Bar/Line/Pie).
- **Batch G** ✅ — Icon presets: lucide (default, 1830), tabler (5130),
  phosphor (1512), heroicons (324), hugeicons (6026, converted from the
  free pack's element arrays). `tools/gen_icons.py --preset <name>` builds
  each names table with a curated **semantic role map**; build.zig's
  `-Dicons-preset=<name>` links ONLY the active pack's assets (comptime
  switch; unanalyzed branches embed nothing). All five presets compile
  clean.
- **Batch H** ✅ — Gallery: new "Extras" page (batch A/B/D/E showcase),
  charts page extended with every new chart type; 187/187 library unit
  tests green; interaction selftest 31/31.
- **Batch I** ✅ (2026-09-17) — BoxPlot chart (five-number summaries,
  whiskers, median, outliers; 3 unit tests) + gallery section; raised
  zui `MAX_IMAGE_POOL_BYTES` 8→16MB after measuring the charts working
  set (~8.4MB at 1400px — the new section tipped the pool over and left
  trailing SVGs silently blank); `place()` now logs pool-full drops
  behind `ZUI_LOG`; `ZUI_SNAPSHOT_SCROLL` added for below-fold review.
  192/192 tests green; selftest 31/31.

Still open (phase 2, per section 1–2 notes): sankey/sunburst/boxplot
charts, TreeSelect/Cascader, editor/Markdown full renderer, QR code,
virtual list, dock, RTL — each blocked on framework capabilities noted
above.

Chart type sources downloaded into `.references/charting/`: `d3` 7.9.0,
`echarts` 6.1.0, `recharts` 3.10.1, `@tanstack/charts` 0.18.0.
