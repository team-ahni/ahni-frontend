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

The signature detail is an accent-soft summary surface that gives the current task or student identity visual priority without decorative illustration or fake product data.

## 2. Tokens

### Color

Tokens live in `lib/app/app_theme.dart` (`AppColors`). Screens read them through `Theme.of(context).colorScheme`, never as literals.

| Role | Token | Value |
| --- | --- | --- |
| Canvas | `canvas` | `#F7F8FA` |
| Surface | white | `#FFFFFF` |
| Field, chip, disabled fill | `subtle` | `#EEF1F4` |
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
- Title (`titleLarge`, app bar): 20/28, weight 700, letter spacing -0.4.
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

## 4. Components

### App shell

- Material 3 root with `AHNI` as the semantic application title.
- Neutral canvas, dark system status icons, and a restrained text-first top bar.
- The environment label is supporting developer information, not a user-facing production badge.
- Keep onboarding copy warm, specific, and concise. Do not repeat the app or screen purpose in an eyebrow label.
- Wrap Korean headings and explanatory copy only at whitespace boundaries with `WhitespaceWrappedText`; never add manual line breaks for a viewport. Identifiers and other unbroken values must use explicit overflow handling instead.

### Segmented control

- Use for two to four peer filters or modes such as login/sign-up and enrollment status.
- Selected state uses the white surface and primary text; unselected state stays on the neutral canvas with secondary text.
- Every segment keeps a 44-pixel minimum touch target and visible selected semantics.
- Authentication modes do not share entered credentials, validation state, or feedback messages.

### Section card

- White surface, 20-pixel radius, 20-pixel internal padding, no shadow. The grey canvas alone separates cards.
- A card groups one complete user task. Nested cards are not allowed.
- Passive loading indicators are not cards; show them directly on the canvas.

### Form field

- Soft filled field: `subtle` fill, 14 radius, no resting border, so there is no Material outline notch.
- The label always sits small inside the top of the field (13/600, `supportingText`; accent on focus, error ink on error). Units such as `년` and `학점` are suffix text in secondary color.
- Focus draws a 1.5 accent border; errors draw a danger border.
- Focus state uses the accent outline. Error text remains inline and is never communicated by color alone.

### Department selector

- Use one labeled dropdown for each major type instead of combining multiple meanings in one control.
- The primary department is required. Double-major and minor selectors are explicitly marked as optional and include `선택 안 함`.
- Prevent the same department from being assigned to more than one major type, and preserve all selections when a server request fails.

### Profile summary

- Accent-soft surface containing the student's display identity, primary department, and account or enrollment status.
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
