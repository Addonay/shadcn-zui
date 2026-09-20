//! Component tree, mirroring gpui-kit's `component::*` namespaces.
//!
//! Every component lives in its own folder (`components/<name>.zig`) and
//! exposes a builder with a `render() zui.Element` method.

// -- layout & display -------------------------------------------------------
pub const accordion = @import("accordion.zig");
pub const affix = @import("affix.zig");
pub const aspect_ratio = @import("aspect_ratio.zig");
pub const attachment = @import("attachment.zig");
pub const bubble = @import("bubble.zig");
pub const code = @import("code.zig");
pub const comment = @import("comment.zig");
pub const field = @import("field.zig");
pub const highlight = @import("highlight.zig");
pub const image = @import("image.zig");
pub const indicator = @import("indicator.zig");
pub const item = @import("item.zig");
pub const marker = @import("marker.zig");
pub const message = @import("message.zig");
pub const nav_link = @import("nav_link.zig");
pub const result = @import("result.zig");
pub const shimmer = @import("shimmer.zig");
pub const statistic = @import("statistic.zig");
pub const status_bar = @import("status_bar.zig");
pub const tag = @import("tag.zig");
pub const timeline = @import("timeline.zig");
pub const alert = @import("alert.zig");
pub const avatar = @import("avatar.zig");
pub const avatar_group = @import("avatar_group.zig");
pub const badge = @import("badge.zig");
pub const breadcrumb = @import("breadcrumb.zig");
pub const calendar = @import("calendar.zig");
pub const button = @import("button.zig");
pub const button_group = @import("button_group.zig");
pub const card = @import("card.zig");
pub const collapsible = @import("collapsible.zig");
pub const description_list = @import("description_list.zig");
pub const empty = @import("empty.zig");
pub const group_box = @import("group_box.zig");
pub const kbd = @import("kbd.zig");
pub const label = @import("label.zig");
pub const link = @import("link.zig");
pub const separator = @import("separator.zig");
pub const skeleton = @import("skeleton.zig");
pub const loading_overlay = @import("loading_overlay.zig");

// -- controls ---------------------------------------------------------------
pub const checkbox = @import("checkbox.zig");
pub const copy_button = @import("copy_button.zig");
pub const autocomplete = @import("autocomplete.zig");
pub const combobox = @import("combobox.zig");
pub const color_picker = @import("color_picker.zig");
pub const choice_card = @import("choice_card.zig");
pub const input = @import("input.zig");
pub const input_group = @import("input_group.zig");
pub const multi_select = @import("multi_select.zig");
pub const number_input = @import("number_input.zig");
pub const otp_input = @import("otp_input.zig");
pub const password_input = @import("password_input.zig");
pub const search_field = @import("search_field.zig");
pub const select = @import("select.zig");
pub const time_field = @import("time_field.zig");
pub const progress = @import("progress.zig");
pub const radio_group = @import("radio_group.zig");
pub const rating = @import("rating.zig");
pub const slider = @import("slider.zig");
pub const stepper = @import("stepper.zig");
pub const textarea = @import("textarea.zig");
pub const toggle = @import("toggle.zig");
pub const toggle_group = @import("toggle_group.zig");

// -- navigation & structure -------------------------------------------------
pub const carousel = @import("carousel.zig");
pub const list = @import("list.zig");
pub const menubar = @import("menubar.zig");
pub const navigation_menu = @import("navigation_menu.zig");
pub const pagination = @import("pagination.zig");
pub const scroll_area = @import("scroll_area.zig");
pub const sidebar = @import("sidebar.zig");
pub const tabs = @import("tabs.zig");
pub const table = @import("table.zig");
pub const data_table = @import("data_table.zig");

// -- overlays ---------------------------------------------------------------
pub const context_menu = @import("context_menu.zig");
pub const dialog = @import("dialog.zig");
pub const dropdown_button = @import("dropdown_button.zig");
pub const dropdown_menu = @import("dropdown_menu.zig");
pub const fab = @import("fab.zig");
pub const hover_card = @import("hover_card.zig");
pub const popover = @import("popover.zig");
pub const segmented = @import("segmented.zig");
pub const sheet = @import("sheet.zig");
pub const questionnaire = @import("questionnaire.zig");
pub const resizable = @import("resizable.zig");
pub const text_view = @import("text_view.zig");
pub const tooltip = @import("tooltip.zig");
pub const transfer = @import("transfer.zig");
pub const tree = @import("tree.zig");

// -- feedback ---------------------------------------------------------------
pub const command = @import("command.zig");
pub const icon = @import("icon/root.zig");
pub const spinner = @import("spinner.zig");
pub const toast = @import("toast.zig");

// -- charts -----------------------------------------------------------------
pub const chart = @import("chart/root.zig");

// `switch` is a Zig keyword: quoted identifier, friendlier alias.
pub const @"switch" = @import("switch.zig");
pub const switch_toggle = @"switch";

// -- re-exports -------------------------------------------------------------
pub const Accordion = accordion.Accordion;
pub const Alert = alert.Alert;
pub const Avatar = avatar.Avatar;
pub const AvatarGroup = avatar_group.AvatarGroup;
pub const Badge = badge.Badge;
pub const Breadcrumb = breadcrumb.Breadcrumb;
pub const Calendar = calendar.Calendar;
pub const RangeCalendar = calendar.RangeCalendar;
pub const CalDate = calendar.Date;
pub const Button = button.Button;
pub const ButtonGroup = button_group.ButtonGroup;
pub const IconButton = button.IconButton;
pub const Card = card.Card;
pub const Collapsible = collapsible.Collapsible;
pub const DescriptionList = description_list.DescriptionList;
pub const Empty = empty.Empty;
pub const GroupBox = group_box.GroupBox;
pub const Kbd = kbd.Kbd;
pub const Label = label.Label;
pub const Link = link.Link;
pub const Separator = separator.Separator;
pub const Skeleton = skeleton.Skeleton;

pub const Affix = affix.Affix;
pub const AspectRatio = aspect_ratio.AspectRatio;
pub const Attachment = attachment.Attachment;
pub const Bubble = bubble.Bubble;
pub const Code = code.Code;
pub const Comment = comment.Comment;
pub const Field = field.Field;
pub const Highlight = highlight.Highlight;
pub const Image = image.Image;
pub const Indicator = indicator.Indicator;
pub const Item = item.Item;
pub const Marker = marker.Marker;
pub const Message = message.Message;
pub const NavLink = nav_link.NavLink;
pub const Result = result.Result;
pub const Shimmer = shimmer.Shimmer;
pub const Statistic = statistic.Statistic;
pub const StatusBar = status_bar.StatusBar;
pub const Tag = tag.Tag;
pub const Timeline = timeline.Timeline;
pub const LoadingOverlay = loading_overlay.LoadingOverlay;

pub const Carousel = carousel.Carousel;
pub const List = list.List;
pub const ListItem = list.Item;
pub const Menubar = menubar.Menubar;
pub const MenubarTrigger = menubar.Trigger;
pub const NavigationMenu = navigation_menu.NavigationMenu;
pub const NavigationLink = navigation_menu.Link;
pub const Tree = tree.Tree;
pub const TreeRow = tree.Row;
pub const Transfer = transfer.Transfer;
pub const TextView = text_view.TextView;
pub const TextViewBlock = text_view.Block;
pub const Questionnaire = questionnaire.Questionnaire;
pub const Resizable = resizable.Resizable;

pub const Autocomplete = autocomplete.Autocomplete;
pub const Checkbox = checkbox.Checkbox;
pub const ChoiceCard = choice_card.ChoiceCard;
pub const Combobox = combobox.Combobox;
pub const ColorPicker = color_picker.ColorPicker;
pub const InputGroup = input_group.InputGroup;
pub const MultiSelect = multi_select.MultiSelect;
pub const NumberInput = number_input.NumberInput;
pub const OtpInput = otp_input.OtpInput;
pub const PasswordInput = password_input.PasswordInput;
pub const SearchField = search_field.SearchField;
pub const Select = select.Select;
pub const SelectOption = select.Option;
pub const TimeField = time_field.TimeField;
pub const ContextMenu = context_menu.ContextMenu;
pub const DropdownButton = dropdown_button.DropdownButton;
pub const Fab = fab.Fab;
pub const HoverCard = hover_card.HoverCard;
pub const Segmented = segmented.Segmented;
pub const Input = input.Input;
pub const CopyButton = copy_button.CopyButton;
pub const Progress = progress.Progress;
pub const RadioGroup = radio_group.RadioGroup;
pub const Rating = rating.Rating;
pub const Slider = slider.Slider;
pub const Stepper = stepper.Stepper;
pub const Switch = @"switch".Switch;
pub const Textarea = textarea.Textarea;
pub const Toggle = toggle.Toggle;
pub const ToggleGroup = toggle_group.ToggleGroup;

pub const Pagination = pagination.Pagination;
pub const ScrollArea = scroll_area.ScrollArea;
pub const Sidebar = sidebar.Sidebar;
pub const Table = table.Table;
pub const Tabs = tabs.Tabs;
pub const DataTable = data_table.DataTable;

pub const Dialog = dialog.Dialog;
pub const DropdownMenu = dropdown_menu.DropdownMenu;
pub const Popover = popover.Popover;
pub const Sheet = sheet.Sheet;
pub const Tooltip = tooltip.Tooltip;

pub const Command = command.Command;
pub const Icon = icon.Icon;
pub const Spinner = spinner.Spinner;
pub const Toast = toast.Toast;

pub const AreaChart = chart.AreaChart;
pub const BarChart = chart.BarChart;
pub const Box = chart.Box;
pub const BoxPlot = chart.BoxPlot;
pub const Candle = chart.Candle;
pub const Candlestick = chart.Candlestick;
pub const ComposedChart = chart.ComposedChart;
pub const FunnelChart = chart.FunnelChart;
pub const GaugeChart = chart.GaugeChart;
pub const HBarChart = chart.HBarChart;
pub const Heatmap = chart.Heatmap;
pub const LineChart = chart.LineChart;
pub const PieChart = chart.PieChart;
pub const RadarChart = chart.RadarChart;
pub const ScatterChart = chart.ScatterChart;
pub const ScatterPoint = chart.ScatterPoint;
pub const Sparkline = chart.Sparkline;
pub const StackedAreaChart = chart.StackedAreaChart;
pub const StackedBarChart = chart.StackedBarChart;
pub const Treemap = chart.Treemap;
pub const WaterfallChart = chart.WaterfallChart;

test {
    @import("std").testing.refAllDecls(@This());
}
