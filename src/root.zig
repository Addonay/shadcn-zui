//! shadcn-zui: shadcn/ui-styled components for the ZUI framework.
//!
//! Layout mirrors `gpui-kit`: `shadcn_zui::components::button`,
//! `components::badge`, `components::card`, ... plus `theme` and `support`.
//!
//! ```zig
//! const shadcn = @import("shadcn-zui");
//! const zui = shadcn.zui;
//!
//! shadcn.Button.init("save").variant(.primary).onClick(click).render()
//! ```

/// Re-exported so apps depend on one import for both.
pub const zui = @import("zui");

pub const theme = @import("theme.zig");
pub const support = @import("support.zig");
pub const components = @import("components/root.zig");

/// gpui-kit calls this namespace `component`; keep the alias.
pub const component = components;

// Layout & display
pub const Accordion = components.Accordion;
pub const AccordionItem = components.accordion.Item;
pub const Alert = components.Alert;
pub const Avatar = components.Avatar;
pub const AvatarGroup = components.AvatarGroup;
pub const Badge = components.Badge;
pub const timeline = components.timeline;
pub const Breadcrumb = components.Breadcrumb;
pub const Calendar = components.Calendar;
pub const RangeCalendar = components.RangeCalendar;
pub const BreadcrumbItem = components.breadcrumb.Item;
pub const Autocomplete = components.Autocomplete;
pub const Button = components.Button;
pub const ChoiceCard = components.ChoiceCard;
pub const Combobox = components.Combobox;
pub const ColorPicker = components.ColorPicker;
pub const ContextMenu = components.ContextMenu;
pub const DropdownButton = components.DropdownButton;
pub const Fab = components.Fab;
pub const HoverCard = components.HoverCard;
pub const InputGroup = components.InputGroup;
pub const List = components.List;
pub const ListItem = components.ListItem;
pub const Menubar = components.Menubar;
pub const MenubarTrigger = components.MenubarTrigger;
pub const MultiSelect = components.MultiSelect;
pub const NavigationMenu = components.NavigationMenu;
pub const NavigationLink = components.NavigationLink;
pub const NumberInput = components.NumberInput;
pub const OtpInput = components.OtpInput;
pub const PasswordInput = components.PasswordInput;
pub const SearchField = components.SearchField;
pub const Segmented = components.Segmented;
pub const Select = components.Select;
pub const SelectOption = components.SelectOption;
pub const TimeField = components.TimeField;
pub const TextView = components.TextView;
pub const TextViewBlock = components.TextViewBlock;
pub const Questionnaire = components.Questionnaire;
pub const Resizable = components.Resizable;
pub const Carousel = components.Carousel;
pub const Tree = components.Tree;
pub const TreeRow = components.TreeRow;
pub const Transfer = components.Transfer;
pub const ButtonGroup = components.ButtonGroup;
pub const IconButton = components.IconButton;
pub const Card = components.Card;
pub const CardMetric = components.card.Metric;
pub const Collapsible = components.Collapsible;
pub const DescriptionList = components.DescriptionList;
pub const DescriptionItem = components.description_list.Item;
pub const Empty = components.Empty;
pub const GroupBox = components.GroupBox;
pub const Kbd = components.Kbd;
pub const Label = components.Label;
pub const Link = components.Link;
pub const Separator = components.Separator;
pub const Skeleton = components.Skeleton;

// Batch A additions (display & misc)
pub const Affix = components.Affix;
pub const AspectRatio = components.AspectRatio;
pub const Attachment = components.Attachment;
pub const Bubble = components.Bubble;
pub const Code = components.Code;
pub const Comment = components.Comment;
pub const Field = components.Field;
pub const Highlight = components.Highlight;
pub const Image = components.Image;
pub const Indicator = components.Indicator;
pub const Item = components.Item;
pub const Marker = components.Marker;
pub const Message = components.Message;
pub const NavLink = components.NavLink;
pub const Result = components.Result;
pub const Shimmer = components.Shimmer;
pub const Statistic = components.Statistic;
pub const StatusBar = components.StatusBar;
pub const Tag = components.Tag;
pub const Timeline = components.Timeline;

// Controls
pub const Checkbox = components.Checkbox;
pub const CopyButton = components.CopyButton;
pub const Input = components.Input;
pub const Progress = components.Progress;
pub const RadioGroup = components.RadioGroup;
pub const RadioGroupItem = components.radio_group.Item;
pub const Rating = components.Rating;
pub const Slider = components.Slider;
pub const Stepper = components.Stepper;
pub const StepperItem = components.stepper.Item;
pub const Switch = components.Switch;
pub const Textarea = components.Textarea;
pub const Toggle = components.Toggle;
pub const ToggleGroup = components.ToggleGroup;
pub const ToggleGroupItem = components.toggle_group.Item;

// Navigation & structure
pub const Pagination = components.Pagination;
pub const PaginationItem = components.pagination.Item;
pub const pagination = components.pagination;
pub const ScrollArea = components.ScrollArea;
pub const scroll_area = components.scroll_area;
pub const Sidebar = components.Sidebar;
pub const SidebarItem = components.sidebar.Item;
pub const SidebarGroup = components.sidebar.Group;
pub const Table = components.Table;
pub const TableColumn = components.table.Column;
pub const TableRow = components.table.Row;
pub const DataTable = components.DataTable;
pub const DataTableColumn = components.data_table.Column;
pub const DataTableSort = components.data_table.SortState;
pub const Tabs = components.Tabs;
pub const TabItem = components.tabs.Item;

// Overlays
pub const Dialog = components.Dialog;
pub const AlertDialog = components.dialog.AlertDialog;
pub const DropdownMenu = components.DropdownMenu;
pub const DropdownMenuItem = components.dropdown_menu.Item;
pub const Popover = components.Popover;
pub const Sheet = components.Sheet;
pub const Tooltip = components.Tooltip;

// Feedback
pub const Command = components.Command;
pub const CommandItem = components.command.Item;
pub const Icon = components.Icon;
pub const Spinner = components.Spinner;
pub const Toast = components.Toast;

// Charts
pub const AreaChart = components.AreaChart;
pub const Candle = components.Candle;
pub const Candlestick = components.Candlestick;
pub const ComposedChart = components.ComposedChart;
pub const FunnelChart = components.FunnelChart;
pub const GaugeChart = components.GaugeChart;
pub const HBarChart = components.HBarChart;
pub const Heatmap = components.Heatmap;
pub const RadarChart = components.RadarChart;
pub const ScatterChart = components.ScatterChart;
pub const ScatterPoint = components.ScatterPoint;
pub const Sparkline = components.Sparkline;
pub const StackedAreaChart = components.StackedAreaChart;
pub const StackedBarChart = components.StackedBarChart;
pub const Treemap = components.Treemap;
pub const WaterfallChart = components.WaterfallChart;
pub const BarChart = components.BarChart;
pub const BarChartGroup = components.chart.bar.Group;
pub const Box = components.Box;
pub const BoxPlot = components.BoxPlot;
pub const ChartSeries = components.chart.Series;
pub const LineChart = components.LineChart;
pub const ChartLine = components.chart.line.Line;
pub const PieChart = components.PieChart;
pub const PieSlice = components.chart.pie.Slice;

test {
    @import("std").testing.refAllDecls(@This());
}
