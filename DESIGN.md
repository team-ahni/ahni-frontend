# AHNI Mobile Design System

## 0. Reference contract

- Product references: the supplied AHNI wireframe, use-case specification, ERD, DFD, and mini specification.
- Visual reference: [Student Portal Dashboard Mobile App UI Design](https://dribbble.com/shots/26239990-Student-Portal-Dashboard-Mobile-App-UI-Design) by Ronas IT.
- Layout principles (2026-11): flat cards on a neutral canvas, tinted secondary buttons, and a text-first bottom bar. These are general mobile conventions shared by many Korean finance and lifestyle apps; AHNI keeps its own palette and does not reproduce any specific product's colors, typeface, or brand assets.
- Reuse the reference's calm dashboard hierarchy, inset content cards, compact segmented controls, and profile-summary composition. Do not copy its brand assets, sample data, or purple/green palette.
- This harness branch implements only a development-ready shell. Product screens remain feature work.
- The wireframe's student-first information architecture is authoritative for future flows; it is not copied into placeholder UI.

## 1. Direction

AHNI is a calm, trustworthy academic tool. The surface is light and restrained, with one blue accent that connects the product to its Inha University origin without hard-coding university-specific behavior. Information is grouped like a student portal dashboard: clear screen title, one dominant task or summary, then quiet supporting cards.

The signature detail is an accent-soft summary surface that gives the current task or student identity visual priority without fake product data. The only illustration is the AHNI character '아니' (see Components).

## 2. Tokens

### Color

Tokens live in `lib/app/app_theme.dart` (`AppColors`). Screens read them through `Theme.of(context).colorScheme`, never as literals.

| Role | Token | Value |
| --- | --- | --- |
| Canvas | `canvas` | `#F7F8FA` |
| Surface | white | `#FFFFFF` |
| Chip, disabled fill | `subtle` | `#EEF1F4` |
| Divider, field border | `line` | `#DDE2E8` |
| Placeholder, disabled text | `muted` | `#9AA3AE` |
| Supporting text, inactive tab | `supportingText` | `#646E7A` |
| Secondary text | `secondaryText` | `#5B6470` |
| Primary text | `primaryText` | `#18202A` |
| Snack bar | `inverse` | `#2A323D` |
| Accent (AHNI blue) | `accent` | `#1558A6` |
| Accent soft (summary, secondary button) | `accentSoft` | `#EAF2FC` |
| Accent text on soft | `accentStrong` | `#0F4A8C` |
| Error | `danger` / `dangerSoft` / `dangerStrong` | `#D63B3B` / `#FDECEC` / `#A52A2A` |

Text colors meet WCAG AA on white and on the canvas; `muted` is only for placeholders and disabled states.

#### Category tones

`AhniPalette` (`lib/core/presentation/ahni_palette.dart`, a `ThemeExtension`) holds pastel `soft`/`ink` pairs for telling categories apart. Every `ink` meets 4.5:1 on its `soft`. Color never carries meaning alone; a label is always shown.

| Tone | Soft / ink | Used for |
| --- | --- | --- |
| `blue` | `#E6F0FB` / `#14529C` | Major, "this term" recommendation |
| `teal` | `#E2F4F0` / `#12695A` | General education |
| `amber` | `#FBF1DD` / `#8A5A0B` | Free elective, overdue recommendation |
| `rose` | `#FCE9EC` / `#A3304A` | Graduation-required recommendation |
| `violet` | `#EFEAFB` / `#5B3FA8` | Retake recommendation |

Surfaces are flat: no card shadows. Only status semantics may add colors beyond this set.

### Type

- Use the platform system sans-serif so Korean and Latin text render consistently without a network font dependency.
- Display (`headlineMedium`): 24/32, weight 700, letter spacing -0.5.
- Title (`titleLarge`, app bar): 20/28, weight 700, letter spacing -0.4. App bar titles are left-aligned on every platform.
- Section title (`titleMedium`): 17/24, weight 600.
- Lead body (`bodyLarge`): 16/24, weight 400, primary text. Field values use this style; screen description paragraphs lower it to `onSurfaceVariant`.
- Body (`bodyMedium`): 15/22, weight 400.
- Supporting (`bodySmall`): 13/19, weight 400.
- Korean body text uses letter spacing -0.3. Component text (buttons, chips, tabs, snack bars) derives from the theme text styles so it never falls back to a different platform font.

### Space and shape

- Base spacing unit: 4 logical pixels.
- Screen gutter: 24.
- Content gaps: 8, 12, 16, 24, 32.
- Small control radius: 8 (chips), 10.
- Input and secondary button radius: 12.
- Primary button: 56 high, radius 16.
- Surface and dialog radius: 20; bottom sheet top radius 24.

## 3. Layout

- Respect safe areas and one-handed mobile use.
- Keep the primary message above the fold on compact phones.
- Use cards only to group a complete task, summary, or related data set. Do not wrap individual labels or every section in separate cards.
- Keep screen titles and primary actions outside cards; place form controls and profile details inside one dominant content card.
- Future navigation follows the supplied wireframe and must be implemented per feature, not pre-created as inactive controls.

## Voice

- Write all user-facing copy, including errors, in polite casual 해요체 (`~했어요`, `~해 주세요`). Do not mix in `~습니다`.
- Headlines describe what the screen offers (`학기별 성적을 한눈에 봐요`) rather than command the user (`~하세요`).

## 4. Components

### App shell

- Material 3 root with `AHNI` as the semantic application title.
- Neutral canvas, dark system status icons, and a restrained text-first top bar.
- The environment label is supporting developer information, not a user-facing production badge.
- Keep onboarding copy warm, specific, and concise. Do not repeat the app or screen purpose in an eyebrow label.
- Wrap Korean headings and explanatory copy only at whitespace boundaries with `WhitespaceWrappedText`; never add manual line breaks for a viewport. Identifiers and other unbroken values must use explicit overflow handling instead.
- `WhitespaceWrappedText` lays out one `Text` per word in a `Wrap`, so the engine measures every word it paints. Do not go back to inserting invisible joiners (U+2060): with negative letter spacing they made lines measure narrower than they paint and clipped the last syllable.
- `test/widget/layout_resilience_test.dart` opens every main screen at 320pt (1.0x, 1.6x text) and 390pt (2.0x text) and fails on any layout overflow. Add new screens to it.
- Dropdowns always set `isExpanded: true` so long items ellipsize instead of overflowing narrow columns.

### Segmented control

- Use for two to four peer filters or modes such as login/sign-up and enrollment status.
- Selected state uses the white surface and primary text; unselected state stays on the neutral canvas with secondary text.
- Every segment keeps a 44-pixel minimum touch target and visible selected semantics.
- Authentication modes do not share entered credentials, validation state, or feedback messages.

### Info group (settings list)

- `SectionHeader` + `InfoGroup` + `InfoRow`/`NavigationRow` in `lib/core/presentation/info_group.dart`.
- A small 13/600 section title sits above a white 20-radius group. Rows put the label left in secondary text and the value right in 15/600 primary text, separated by inset 1-pixel dividers.
- Navigation rows lead with a 36-pixel accent-soft icon tile and end with a chevron.
- Use for read-mostly profile and settings data instead of stacked label/value pairs inside a section card.

### Notice callout

- `NoticeCallout` (`lib/core/presentation/friendly_states.dart`): a 14-radius soft box with an 18-point icon and 13-point copy. Use it for screen intros and caveats instead of dense paragraphs. Default tone is accent soft; caveats may use an `AhniPalette` tone (for example amber for missing data, violet for retake rules).

### Character '아니'

- AHNI is INHA spelled backwards; '아니' is the friend who looks at school from the student's side. A round AHNI-blue body, a light belly, and a two-leaf sprout that grows each semester.
- `AhniMascot` (`lib/core/presentation/ahni_mascot.dart`) is drawn in code: no image files or packages, sharp at any size. Its colors are fixed art colors inside that file, not theme tokens.
- Moods: `hello` (first visit, nothing yet), `curious` (something is needed), `oops` (load failure, expired login), `cheer` (a task is done).
- Places: the login header (88) and every `EmptyStateView` (104). Do not put it on data screens, cards, or buttons; one character per screen at most.
- It is decorative and excluded from semantics; the title next to it carries the meaning.
- Original art only. Never use or imitate Inha University's mascots (안뇽이, 인덕이): they are trademark-pending and need the university's prior permission.

### Same situation, same pattern

- One situation gets one UI pattern across every flow. Before building or fixing a flow, find where the app already handles the same situation and reuse that component; the second use is the moment to extract it.
- Timetable overlap: every flow that puts a lecture into the timetable (single add, change, recommendation add, registration import) checks overlaps on the client and asks with `showTimetableConflictDialog` (`lib/features/timetable/presentation/timetable_conflict_dialog.dart`): an `old → new` list and two equal buttons on one row, `다시 선택하기 | 바꾸기`. Never a three-button vertical dialog, never an inline decision panel.
- Refusals that the client could not foresee (server errors) appear in a SnackBar, not in the page's load-error area.
- Shared components for recurring situations (2026-11 audit):
  - Every confirmation: `showConfirmDialog` (`lib/core/presentation/confirm_dialog.dart`). Title is a question ("강의를 삭제할까요?"), two equal buttons on one row, back-off on the left and the action on the right; deletions pass `destructive` for the danger color.
  - Load failure of a screen's data: `LoadFailureView` (`friendly_states.dart`): '아니' oops, a "○○을 불러오지 못했어요" title, the server reason, and a filled "다시 시도". An empty-but-valid result (no graduation policy yet) is an `EmptyStateView`, not a failure.
  - Form or save errors inside a form: `ErrorNotice` (error container, icon, live region). Never plain red text.
  - A lecture shown for adding to the timetable: `LectureCard` (`lib/features/timetable/presentation/lecture_card.dart`) with code-section, credit, professor, time, classroom, "이미 있음" and overlap warnings. The picker and the registration import share it.
- Every `LabeledField` input must be announced by name: dropdowns merge the label into their semantics. `test/widget/accessibility_guidelines_test.dart` opens the main screens and checks tap targets (Android 48, iOS 44), labeled tap targets and text contrast.

### Empty state

- `EmptyStateView`: '아니' in the matching mood, a short title, an optional one-line explanation, and the next action. Use it for empty lists, failures, and re-login prompts.

### Section card

- White surface, 20-pixel radius, 20-pixel internal padding, no shadow. The grey canvas alone separates cards.
- A card groups one complete user task. Nested cards are not allowed.
- Passive loading indicators are not cards; show them directly on the canvas.

### Form field

- Label above, outlined box (2026-11; replaces the soft filled field with an inside label). Researched on Dribbble/Pinterest login and form shots and Baymard's mobile form studies: a label that always stays visible above the box is the common, most readable pattern.
- Wrap every field in `LabeledField` (`lib/core/presentation/labeled_field.dart`). Never put `labelText` in `InputDecoration`; the name is `FieldLabel` above the box (13/600, primary text, 8 gap) and is merged with the field for screen readers. Chip groups that act as one input use `FieldLabel` alone.
- Box: white fill, 1px `line` border, 12 radius, 16×12 padding (48 high for one line). Disabled uses a `subtle` border.
- Focus draws a 1.5 accent border; errors draw a danger border with inline error text below, never color alone.
- Placeholders use `muted` and show an example (`student@inha.edu`), not the label again. Units such as `년` and `학점` are suffix text in secondary color.

### Department selector

- Use one labeled dropdown for each major type instead of combining multiple meanings in one control.
- The primary department is required. Double-major and minor selectors are explicitly marked as optional and include `선택 안 함`.
- Prevent the same department from being assigned to more than one major type, and preserve all selections when a server request fails.

### Profile summary

- White surface with the accent avatar, the display name in title size, `department · admission year` as supporting text, and an accent-soft enrollment badge.
- Use only real profile data; omit unavailable dashboard metrics rather than inventing placeholders.

### Grade summary

- White surface with the cumulative GPA at 34 with tabular figures, then credits as supporting text.
- Category GPAs are tone tiles (major `blue`, general `teal`, elective `amber`) with an icon, label, GPA, and credits. Three columns from 300 logical pixels, otherwise two.

### Grade list

- Group grade rows by academic year and term so the section heading is the primary navigation cue.
- Use one section surface per term and separate courses with quiet dividers; do not wrap every course in its own card.
- Course name leads each row. Course code, credits, RPL, and retake information remain supporting metadata.
- Grade codes are right-aligned text with strong contrast. Do not calculate or display a GPA until the backend provides the policy result.
- Loading appears directly on the canvas. Empty and recoverable-error states use concise guidance, and errors provide a 44-pixel retry action.

### Grade simulation

- Enter from the calculator action in the grade screen, including an empty grade history.
- Use a single expected-course form surface with category, credit, and expected grade; separate courses with quiet dividers rather than nested cards.
- Current and projected GPA share one accent-soft comparison surface; numbers use the 24-pixel display size and tabular figures. Large text wraps the two metrics instead of squeezing them into fixed columns.
- Expected grades are temporary. Input changes clear stale results; request failures preserve inputs and offer recalculation. State explicitly that actual records are unchanged.

### Bottom navigation

- Show bottom navigation only after an authenticated student profile is ready.
- The real destinations are `성적`, `졸업`, and `내 정보`; inactive or future destinations are not shown. Graduation progress separates recorded credits from official school certification and displays its policy source.
- White bar without a selection pill: the selected icon and label use primary text, inactive ones `supportingText`.
- Preserve a clear selected label and icon, and reset student-owned feature state when the authenticated student changes.

### Timetable

- Lecture blocks have no border: an 8-radius `AhniPalette.cycle` tone fill, the course name in 12/600 ink, and the classroom on a second 10-point line.
- The same course keeps one tone on every day; different courses take tones in registration order.

### Progress

- Linear progress bars are 8 pixels high with 4-radius ends on a `subtle` track.
- Use a linear bar only for a known ratio (for example credits completed out of required). Waiting of unknown length always uses a centered `CircularProgressIndicator`, never an indeterminate linear bar.

### Buttons

- Primary (`FilledButton`): accent fill, white 17/600 label, 56 high.
- Secondary (`OutlinedButton`): `accentSoft` fill, `accentStrong` label, no border. A grey fill would vanish on the canvas.
- Text actions (`TextButton`): accent label, 44-pixel minimum target.

### Status message

- Inline live region within the related task card.
- Informational messages use accent soft; errors use semantic error colors with readable text.

## 5. Motion

- No decorative motion in the harness shell.
- Future state transitions must communicate navigation or status, use opacity/transform, and honor reduced-motion preferences.

## 6. Accessibility constraints

- Text contrast must meet WCAG AA.
- Touch targets must be at least 44 logical pixels when interactions are introduced.
- Content order must remain meaningful for screen readers and large text.
- Do not convey status by color alone.

## 7. Responsive behavior

- Compact phones: single reading column with 24-pixel gutters.
- Tablets: center content with a readable maximum width rather than stretching copy edge to edge.
- Landscape: preserve safe areas and avoid vertically centering content that can be clipped.

## 8. Accepted debt

- No dark theme is defined in the harness branch.
- No reusable feature components are created until a real flow needs them.
- Visual fidelity for individual wireframe screens is deferred to their feature branches.
- Additional bottom-navigation destinations remain deferred until each destination has a working screen.
