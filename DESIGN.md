# AHNI Mobile Design System

## 0. Reference contract

- Product references: the supplied AHNI wireframe, use-case specification, ERD, DFD, and mini specification.
- Visual reference: [Student Portal Dashboard Mobile App UI Design](https://dribbble.com/shots/26239990-Student-Portal-Dashboard-Mobile-App-UI-Design) by Ronas IT.
- Visual system reference (2026-11): Toss Design System (TDS) — grey and blue scales, flat white cards on a grey canvas, weak (tinted) secondary buttons, and a text-first bottom bar. Sources: [TDS token summary](https://www.oppadu.com/tools/design-systems-site/brand/toss.html) (third-party measurement, not official values) and [Apps in Toss consumer UX guide](https://developers-apps-in-toss.toss.im/landing-page/landing-page-en/design/consumer-ux-guide). Do not copy Toss brand assets, logo, or its proprietary typeface.
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
| Canvas | `grey100` | `#F2F4F6` |
| Surface | white | `#FFFFFF` |
| Field fill | `grey50` | `#F9FAFB` |
| Divider, field border | `grey200` | `#E5E8EB` |
| Placeholder, inactive tab | `grey400` | `#B0B8C1` |
| Supporting text | `grey600` | `#6B7684` |
| Secondary text | `grey700` | `#4E5968` |
| Primary text | `grey900` | `#191F28` |
| Accent | `blue500` | `#3182F6` |
| Accent soft (summary, weak button) | `blue50` | `#E8F3FF` |
| Accent text on soft | `blue700` | `#1B64DA` |
| Error | `red500` / `red50` / `red700` | `#F04452` / `#FFEEEE` / `#D22030` |

Surfaces are flat: no card shadows. Only status semantics may add colors beyond this set.

### Type

- Use the platform system sans-serif so Korean and Latin text render consistently without a network font dependency.
- Display (`headlineMedium`): 26/35, weight 700, letter spacing -0.6.
- Title (`titleLarge`, app bar): 20/28, weight 700, letter spacing -0.4.
- Section title (`titleMedium`): 17/24, weight 600.
- Lead body (`bodyLarge`): 16/24, weight 400, secondary text.
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

- `grey50` fill with a 1-pixel `grey200` border so fields stay visible on both the canvas and white cards.
- Focus state uses the accent outline. Error text remains inline and is never communicated by color alone.

### Department selector

- Use one labeled dropdown for each major type instead of combining multiple meanings in one control.
- The primary department is required. Double-major and minor selectors are explicitly marked as optional and include `선택 안 함`.
- Prevent the same department from being assigned to more than one major type, and preserve all selections when a server request fails.

### Profile summary

- Accent-soft surface containing the student's display identity, primary department, and account or enrollment status.
- Use only real profile data; omit unavailable dashboard metrics rather than inventing placeholders.

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
- White bar without a selection pill: the selected icon and label use primary text, inactive ones `grey400`.
- Preserve a clear selected label and icon, and reset student-owned feature state when the authenticated student changes.

### Buttons

- Primary (`FilledButton`): accent fill, white 17/600 label, 56 high.
- Secondary (`OutlinedButton`): weak style — `blue50` fill, `blue700` label, no border. Grey would vanish on the grey canvas.
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
