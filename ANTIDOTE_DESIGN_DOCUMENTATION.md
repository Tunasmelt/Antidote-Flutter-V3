# Antidote v2 - React Native UI Design Documentation

## 📋 Project Overview

**Application:** Antidote v2 - Music Playlist Analytics Platform  
**Platform:** React Native (Web Implementation)  
**Design Theme:** Cosmic/Dark Theme with Neon Accents  
**Target Users:** Music enthusiasts, playlist curators, content creators

---

## 🎨 Design System

### Color Palette

```
Primary (Purple):      #7c3aed (265° 83% 58%)
Secondary (Cyan):      #06b6d4 (189° 94% 43%)
Accent (Pink):         #ec4899 (328° 84% 60%)
Background (Deep Space): #0f0f23 (240° 41% 10%)
Card Background:       #1a1a2e (240° 35% 14%)
Text Primary:          #f2f2f2 (240° 10% 95%)
Text Muted:           #7a7a8f (240° 10% 70%)
Border:               #3e3e4e (240° 30% 25%)
Success (Green):      #10b981 (160° 84% 39%)
Warning (Yellow):     #f59e0b (38° 92% 50%)
```

### Typography

| Font | Usage | Weight | Purpose |
|------|-------|--------|---------|
| **Press Start 2P** | Brand Logo, Main Headers | 400 | Pixel art aesthetic, brand identity |
| **Space Mono** | Code, Data, Technical Text | 400, 700 | Technical feel for input/data fields |
| **Inter** | Body Text, UI Labels | 300-700 | Clean, readable sans-serif |

### Spacing & Sizing

- **Base Unit:** 4px (Tailwind's default)
- **Radius:** 8px (sm), 12px (md), 16px (lg)
- **Shadows:** Custom glow effects (0 0 20px rgba(124, 58, 237, 0.6))
- **Mobile Frame:** 400px wide × 850px tall (iPhone mockup)

---

## 🏗️ UI Structure

### Directory Organization

```
client/src/
├── pages/
│   ├── Home.tsx                    # Landing/Entry screen
│   ├── Analysis.tsx                # Playlist analysis results
│   ├── Battle.tsx                  # Head-to-head comparison
│   ├── MusicDecisionAssistant.tsx  # AI track suggestions
│   ├── Profile.tsx                 # User profile & settings
│   └── not-found.tsx               # 404 page
├── components/
│   ├── layout/
│   │   └── MobileLayout.tsx        # iPhone frame wrapper
│   └── ui/                         # Shadcn/UI components
├── lib/
│   ├── utils.ts                    # Utility functions (cn())
│   └── queryClient.ts              # React Query setup
└── index.css                       # Global styles & animations
```

---

## 📱 Screen Wireframes & Component Breakdown

### 1. HOME SCREEN
**Path:** `/`

#### Wireframe
```
┌─────────────────────────────────────┐
│  STATUS BAR  [9:41]  [Signal/Battery]│
├─────────────────────────────────────┤
│                                     │
│         [COSMIC BACKGROUND]         │
│              /ˆ\                    │
│            ◆  •  ◆  (Shooting      │
│        ✦  •    •  • (Stars)         │
│                                     │
│         [ANTIDOTE LOGO]             │
│     (animated rotation & bob)       │
│                                     │
│          ANTIDOTE                   │
│     Discover the DNA of your        │
│         music taste                 │
│                                     │
├─────────────────────────────────────┤
│  ┌─────────────────────────────────┐│
│  │ Playlist URL                    ││
│  │ [PASTE_SPOTIFY_LINK]            ││
│  │                                 ││
│  │  [REVEAL MY DESTINY] →          ││
│  └─────────────────────────────────┘│
├─────────────────────────────────────┤
│ MODULES                             │
│ ┌──────────────┐ ┌──────────────┐  │
│ │ 🏥 Health    │ │ ⚡ Battle     │  │
│ │ Check        │ │ Mode         │  │
│ ├──────────────┤ ├──────────────┤  │
│ │ 🪄 Decision  │ │ 📤 Share &   │  │
│ │ Assistant    │ │ Save         │  │
│ └──────────────┘ └──────────────┘  │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ⭐ Discover More                │ │
│ │ Get songs that fit the vibe     │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│  [Home] [Analysis] [Battle] [Profile]│
│         BOTTOM TAB NAVIGATION        │
└─────────────────────────────────────┘
```

#### Components

**Hero Section**
- Background: Animated space texture with 60% opacity
- Gradient overlay: Dark fade from top to bottom
- Shooting stars: 3-4 animated lines per 8-second loop
  - Colors: Purple (#7c3aed), Cyan (#06b6d4), Pink (#ec4899)
  - Animation: `shootingStar` / `shootingStarReverse` (3s ease-in)

**Logo**
- Size: 96px × 96px
- Animation: Rotation (5° swing) + vertical bob (-10px)
- Duration: 4 seconds (infinite loop)
- Glow: `drop-shadow-[0_0_20px_rgba(124,58,237,0.6)]`

**Main Title "ANTIDOTE"**
- Font: Press Start 2P, 36px
- Animation: Text shadow pulsing (3s loop)
  - From: `0 2px 0px rgba(124, 58, 237, 1)`
  - To: `0 4px 10px rgba(124, 58, 237, 0.8)`
- Drop shadow: Purple glow effect

**Playlist Input Card**
- Background: `rgba(255, 255, 255, 0.05)` with backdrop blur
- Border: 1px solid `rgba(255, 255, 255, 0.1)`
- Radius: 16px
- Entry animation: Scale 0.95 → 1.0 (200ms delay, ease-out)

**"Reveal My Destiny" Button**
- Background: Gradient `primary → pink-600`
- Hover effect: Scale 1.02, overlay appears
- Interaction: Box shadow glow with pink color
- Width: 100% of container

**Feature Cards (4 Modules)**
- Layout: 2×2 grid (gap 16px)
- Hover effects:
  - Y-axis: -5px
  - Scale: 1.02
  - Border color: primary/30 or pink/30 or cyan/30 or purple/30
- Border: 1px solid `rgba(255, 255, 255, 0.05)`
- Background: `rgba(255, 255, 255, 0.03)` hover `rgba(255, 255, 255, 0.05)`
- Icons: Health Check (green), Battle Mode (pink), Decision Assistant (cyan), Share & Save (purple)

**Discover More Card**
- Background: Gradient `indigo-900/20 → purple-900/20`
- Entry animation: Fade in at 500ms delay
- Hover: Scale 1.02
- Icon: Star image from assets

---

### 2. ANALYSIS SCREEN
**Path:** `/analysis`

#### Wireframe
```
┌─────────────────────────────────────┐
│  STATUS BAR  [9:41]  [Signal/Battery]│
├─────────────────────────────────────┤
│ [← Back]                            │
│                                     │
│  ┌────────────┐  SPOTIFY     🕐     │
│  │  [Playlist]│  Late Night Drive   │
│  │   Cover    │  by Alex Doe        │
│  └────────────┘  142 tracks •8h47m  │
│                                     │
├─────────────────────────────────────┤
│ PLAYLIST HEALTH     92/100           │
│ ████████████████░░  Excellent       │
│                                     │
│ Your playlist has consistent energy │
│ flow with minimal genre clutter.    │
├─────────────────────────────────────┤
│                                     │
│         [RADAR CHART]               │
│       Audio DNA Analysis            │
│                                     │
├─────────────────────────────────────┤
│ TOP ARTISTS                         │
│ [Artist1]  [Artist2]  [Artist3]    │
│  🖼️         🖼️         🖼️          │
├─────────────────────────────────────┤
│ PERSONALITY DECODED                 │
│ ▌ Experimental (boundary pusher)   │
│ ▌ Mood-Driven (emotional depth)    │
│ ▌ Eclectic (wide influences)       │
│ ▌ Trend-Aware (modern sound)       │
├─────────────────────────────────────┤
│ GENRE DISTRIBUTION                  │
│ Electronic    28% [████████░░░░]   │
│ Indie         22% [██████░░░░░░]   │
│ Hip-Hop       18% [█████░░░░░░░░]  │
│ Pop           15% [████░░░░░░░░░░] │
│ R&B           12% [███░░░░░░░░░░░] │
│ Other          5% [█░░░░░░░░░░░░░░]│
├─────────────────────────────────────┤
│ TOP SUBGENRES                       │
│ • Synthwave        12%              │
│ • Chillwave        10%              │
│ • Alt Hip-Hop       9%              │
│ • Dream Pop         8%              │
│ • Soul              7%              │
│ • Ambient           6%              │
├─────────────────────────────────────┤
│ OVERALL RATING      ⭐⭐⭐⭐⭐       │
│        4.5/5.0                      │
│ Outstanding composition             │
├─────────────────────────────────────┤
│  [Share Analysis] [Save Report]     │
└─────────────────────────────────────┘
```

#### Components

**Header**
- Back navigation button (ghost style)
- Playlist cover: 96px × 96px, rounded 8px
- Spotify badge: Green (`#1DB954`)
- Title, owner, track count, duration (with clock icon)

**Health Score Card**
- Background: `rgba(255, 255, 255, 0.04)` with blur
- Animated counter: 0 → 92 (500ms)
- Progress bar: Gradient fill with animation
- Status badge: Green "Excellent"

**Audio DNA Radar Chart**
- 6-axis radar: Energy, Dance, Valence, Acoustic, Tempo, Live
- Stroke: `#7c3aed` (purple)
- Grid: Subtle white lines

**Top Artists Section**
- 3-column grid of circular avatars
- Staggered animations (100ms intervals)
- Hover: Border color → cyan

**Personality Decoded Section** ⭐ NEW
- 4 personality traits with descriptions
- Left border accent (primary color)
- Staggered entry animations
- Icons: Heart for section header

**Genre Distribution Section** ⭐ NEW
- 6 genres with animated progress bars
- Color-coded bars (purple, cyan, pink, amber, green, gray)
- Animated fill from 0 to value
- Percentage labels

**Subgenre Distribution Section** ⭐ NEW
- Top 6 subgenres in cards
- Dark background cards
- Cyan percentage text
- Staggered animations

**Overall Rating Section** ⭐ NEW
- 5-star rating system with animation
- Yellow/amber gradient background
- 4.5/5.0 numerical rating
- Descriptive text

**Action Buttons**
- "Share Analysis" & "Save Report"
- Full width, height 40px
- Hover: Background brighten, border glow
- Interactive animations on tap

---

### 3. BATTLE SCREEN
**Path:** `/battle`

#### Initial State (Input Screen)
```
┌─────────────────────────────────────┐
│  STATUS BAR  [9:41]  [Signal/Battery]│
├─────────────────────────────────────┤
│                                     │
│      [⚡ Battle Icon]                │
│    Playlist Battle                  │
│ Compare taste compatibility         │
│                                     │
├─────────────────────────────────────┤
│                                     │
│ CONTENDER 1                         │
│ [Paste first playlist URL...]       │
│                                     │
│           VS (rotating)             │
│                                     │
│ CONTENDER 2                         │
│ [Paste second playlist URL...]      │
│                                     │
├─────────────────────────────────────┤
│  [START BATTLE]                     │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │  🏆  Winner Takes All            │ │
│ │ AI analyzes energy curves,       │ │
│ │ genre overlap & compatibility.   │ │
│ └─────────────────────────────────┘ │
│                                     │
│  [Home] [Analysis] [Battle] [Profile]│
└─────────────────────────────────────┘
```

#### Results State ⭐ REDESIGNED
```
┌─────────────────────────────────────┐
│ [← Back]  Battle Results            │
├─────────────────────────────────────┤
│ COMPATIBILITY ANALYSIS     78%       │
│ Taste compatibility match            │
│ Similar energy with complementary    │
│ genre distributions.                 │
├─────────────────────────────────────┤
│ 🏆  CONTENDER 1 WINS                 │
│ Dominates with higher score &        │
│ better genre cohesion.               │
├─────────────────────────────────────┤
│ PLAYLIST SCORES                      │
│ ┌──────────────┐ ┌──────────────┐  │
│ │ [Cover] 🎵   │ │ [Cover] 🎵   │  │
│ │ Late Night   │ │ Chill        │  │
│ │ Alex Doe     │ │ Sessions     │  │
│ │ 92 / 142     │ │ 88 / 156     │  │
│ └──────────────┘ └──────────────┘  │
├─────────────────────────────────────┤
│ SHARED ARTISTS   5        SHARED     │
│ ┌──────────────┐ ┌──────GENRES──┐   │
│ │ The Weeknd   │ │ • Electronic │   │
│ │ • Daft Punk  │ │ • Hip-Hop    │   │
│ │ ...          │ │ • Indie      │   │
│ └──────────────┘ └──────────────┘   │
├─────────────────────────────────────┤
│ SHARED TRACKS (3)                   │
│ ✓ Blinding Lights - The Weeknd     │
│ ✓ One More Time - Daft Punk        │
│ ✓ The Less I Know... - Tame Impala │
├─────────────────────────────────────┤
│ ADD FROM OTHER PLAYLIST              │
│ ☐ Levitating - Dua Lipa            │
│ ☐ Midnight City - M83              │
│ ☐ Electric Feel - MGMT             │
├─────────────────────────────────────┤
│       [COMBINED AUDIO DNA]           │
│    (Dual-layer radar chart)          │
│  Cyan = Playlist 1, Pink = Playlist 2│
├─────────────────────────────────────┤
│ [Create Merged] [Share Results]     │
└─────────────────────────────────────┘
```

#### Components

**Initial Screen**
- Battle icon: Gradient background pink → purple, 64px
- Icon animation: Rotation swing (10° ±)
- Title & description with staggered animations

**Input Section**
- Contender 1 (cyan): Enters from left
- Contender 2 (pink): Enters from right
- VS Badge: Center absolute, rotating (360°, 20s linear)

**Results Screen Components** ⭐ NEW
- **Compatibility Analysis Card:** 78% score with explanation
- **Winner Declaration:** Trophy icon + outcome (Winner/Loser/Tie)
  - Tie style: Cyan background (both playlists perfectly balanced)
  - Winner style: Yellow background
  - Loser style: Blue background
- **Playlist Score Cards:** 2×1 grid showing:
  - Cover image (rounded)
  - Playlist name
  - Owner name
  - Track count & score
- **Shared Artists Card:** Count + top 2 artists
- **Shared Genres Card:** Count + all genres listed
- **Shared Tracks Section:** Green checkmarks + track details
- **Add from Other Playlist Section:** Interactive checkboxes
  - Unchecked: Gray border
  - Checked: Cyan background with checkmark
- **Combined Audio DNA Radar:** Dual-layer visualization
  - Cyan line: Playlist 1
  - Pink line: Playlist 2
  - 6 axes: Energy, Dance, Valence, Acoustic, Tempo, Live
- **Action Buttons:** 
  - Create Merged Playlist (cyan gradient)
  - Share Results (outlined)

---

### 4. MUSIC DECISION ASSISTANT SCREEN ⭐ NEW
**Path:** `/music-assistant`

#### Wireframe
```
┌─────────────────────────────────────┐
│ [← Back] Music Decision Assistant   │
├─────────────────────────────────────┤
│                                     │
│ 💡 PRO TIP                          │
│ Sign up to unlock personalized      │
│ flavor profiles and smarter         │
│ recommendations across all          │
│ playlists.                          │
│                                     │
├─────────────────────────────────────┤
│ SUGGESTION TYPES (6):               │
│                                     │
│ 💡 Best Next Track                  │
│    AI picks perfect next song       │
│                                     │
│ ❤️  Mood-Safe Pick                  │
│    Maintains current vibe           │
│                                     │
│ 🧭 Rare Match For You               │
│    Hidden gems matching taste       │
│                                     │
│ 🔄 Return To Familiar               │
│    Deep cuts from loved artists     │
│                                     │
│ 🎵 Short Session Mode               │
│    Perfect 5-10 minute tracks       │
│                                     │
│ ⚡ Energy Adjustment                │
│    Shift energy up or down          │
│                                     │
├─────────────────────────────────────┤
│  [Sign Up for More]                 │
│  [Continue as Guest]                │
└─────────────────────────────────────┘
```

#### Components

**Header**
- Back button for navigation
- Title: "Music Decision Assistant"
- Subtitle: "AI-powered suggestions tailored to your taste"

**Auth Notice Card** ⭐ NEW
- Cyan background (`cyan-500/10`)
- Light bulb icon
- Pro tip about personalization benefits
- Encourages signup for better features

**Suggestion Grid** ⭐ NEW
- 6 suggestion types displayed as cards
- Each card has:
  - Color-coded icon (yellow, red, cyan, purple, green, pink)
  - Title (e.g., "Best Next Track")
  - Description of what each suggestion provides
  - Hover: Slight lift + scale effect
- Staggered animations (50ms intervals)

**Feature Details:**
1. **Best Next Track** - Yellow icon (lightbulb)
   - "AI picks the perfect next song based on current momentum"
2. **Mood-Safe Pick** - Red icon (heart)
   - "Maintains your current vibe without jarring changes"
3. **Rare Match For You** - Cyan icon (compass)
   - "Hidden gems that align with your unique taste"
4. **Return To Familiar** - Purple icon (rotate-cw)
   - "Deep cuts from artists you already love"
5. **Short Session Mode** - Green icon (music)
   - "Perfect tracks for quick 5-10 minute breaks"
6. **Energy Adjustment** - Pink icon (zap)
   - "Gradually shift the energy up or down"

**CTA Buttons**
- Primary: "Sign Up for More" (gradient cyan → blue)
- Secondary: "Continue as Guest" (outline style)
- Both animated with hover effects

---

### 5. PROFILE SCREEN
**Path:** `/profile`

#### Wireframe
```
┌─────────────────────────────────────┐
│  STATUS BAR  [9:41]  [Signal/Battery]│
├─────────────────────────────────────┤
│                                     │
│      [User Avatar Bouncing]         │
│       SpaceCadet_99                 │
│   Audio Explorer Lvl. 4             │
│                                     │
├─────────────────────────────────────┤
│ ┌──────────┐ ┌──────────┐ ┌────────┐│
│ │ 42       │ │ 12       │ │ Top 5% ││
│ │ Analyses │ │ Battles  │ │ Taste  ││
│ └──────────┘ └──────────┘ └────────┘│
├─────────────────────────────────────┤
│ 📜 History          12 Recent       │
│ ⭐ Saved Playlists   8 Saved        │
│                                     │
│ ⚙️  Settings                         │
│                                     │
│ 🚪 Log Out                          │
│                                     │
│  [Home] [Analysis] [Battle] [Profile]│
└─────────────────────────────────────┘
```

#### Components

**Profile Header**
- Gradient background: `from-primary/10 to-transparent`
- Avatar: 96px with 4px border, bouncing animation (3s loop)
- Name, badge, entry animations

**Stats Grid**
- 3 columns: Analyses, Battles, Taste Percentile
- Staggered animations (100ms intervals)
- Hover: Scale 1.05

**Menu Items**
- History, Saved Playlists, Settings, Log Out
- Staggered animations (100ms between items)
- Icons with color-coded backgrounds
- Hover: X-axis +5px, background brighten

---

## ✨ Animation Details

### Global Animations

| Animation | Element | Duration | Loop | Effect |
|-----------|---------|----------|------|--------|
| **Shooting Stars** | Home background | 3s | Yes (8s interval) | Multiple colored lines streak diagonally |
| **Logo Rotation** | Home logo | 4s | Infinite | ±5° rotation swing |
| **Logo Bob** | Home logo | 4s | Infinite | -10px vertical movement |
| **Title Glow** | Home title | 3s | Infinite | Text shadow pulse (purple glow) |
| **Background Zoom** | Home bg image | 8s | Infinite | Subtle scale 1 → 1.05 → 1 |
| **Health Counter** | Analysis score | 0.5s delay | Once | Animate 0 → 92 |
| **Rating Animation** | Analysis stars | 0.8s delay | Once | Sequenced star fills (5 stars) |
| **Genre Bars** | Genre distribution | 0.7s+ | Once | Animated fill from 0 to value |
| **Avatar Bob** | Profile avatar | 3s | Infinite | -10px vertical |
| **VS Spin** | Battle VS badge | 20s | Infinite | 360° rotation (linear) |
| **VS Scale** | Battle VS badge | 2s | Infinite | 1 → 1.1 → 1 |
| **Trophy Bob** | Battle trophy icon | 2s | Infinite | -5px vertical |
| **Menu Stagger** | Profile menu items | 100ms intervals | Once | Fade + X-axis shift |

### Micro-interactions

**Button Hover/Tap**
```
Hover: scale(1.02), box-shadow brightens
Tap/Active: scale(0.98)
Transition: 300ms ease-out
```

**Card Hover**
```
Hover: y: -5px, scale(1.02), border color brightens
Transition: All 300ms ease-out
```

**Input Focus**
```
Focus: border-color → cyan/50%, ring-color → cyan/20%
Transition: 150ms ease-out
```

**Checkbox Selection** ⭐ NEW
```
Unchecked: Border white/30%, background white/5%
Checked: Background cyan-500, checkmark white
Transition: 200ms ease-out
```

---

## 🎯 Component Specifications

### MobileLayout Component

**Purpose:** Wraps all pages in an iPhone frame mockup

**Props:**
```typescript
interface MobileLayoutProps {
  children: React.ReactNode;
}
```

**Features:**
- Fixed 400px width, 850px height
- Rounded corners (40px border radius)
- Thick dark border (8px, #1a1a1a)
- Status bar mockup (12px height)
- Bottom tab navigation (80px height)
- Home indicator (pill-shaped, bottom)
- Custom scrollbar styling

**Structure:**
```
MobileLayout
├── Status Bar (fixed top)
├── Content Area (scrollable)
│   └── {children}
├── Bottom Tab Navigation (fixed bottom)
└── Home Indicator
```

**Tab Navigation:**
- Icon + label below
- Active state: Primary color + glow
- Inactive state: Muted color
- Icons: Lucide React (Home, BarChart2, Swords, Wand2, User)

---

## 🛠️ Development Notes

### Key Dependencies Used

```json
{
  "framer-motion": "^12.23.24",     // Animations
  "recharts": "^2.15.4",            // Charts (Radar)
  "lucide-react": "^0.545.0",       // Icons
  "wouter": "^3.3.5",               // Routing
  "react-hook-form": "^7.66.0",     // Forms
  "tailwindcss": "^4.1.14",         // Styling
}
```

### CSS Variables for Theming

All colors defined in `index.css` using HSL with percentages:

```css
--color-primary: hsl(265 83% 58%);      /* Purple */
--color-secondary: hsl(189 94% 43%);    /* Cyan */
--color-background: hsl(240 41% 10%);   /* Deep space */
```

### Responsive Design

- **Desktop (preview):** 400px mobile frame centered on screen with black padding
- **Mobile native:** Adjust viewport to match device dimensions
- **Breakpoints:** Not used (mobile-first, single screen size)

### Performance Optimizations

1. **Lazy animations:** Use `transition={{ delay: ms }}` to stagger loads
2. **Infinite loops:** Use `repeat: Infinity` with appropriate durations
3. **SVG/Images:** Optimized via `object-cover`, `object-contain`
4. **Rendering:** Memoize heavy chart components if needed
5. **GPU acceleration:** Use `transform` and `opacity` for animations (not `left`, `top`)

---

## 📚 File Structure & Dependencies

```
client/src/
├── pages/
│   ├── Home.tsx                    (Shooting stars, logo animation, 4 modules)
│   ├── Analysis.tsx                (Radar chart, health score, personality, genres, rating)
│   ├── Battle.tsx                  (VS badge, compatibility analysis, shared content, merged DNA)
│   ├── MusicDecisionAssistant.tsx  (6 suggestion types, auth messaging)
│   ├── Profile.tsx                 (Staggered menu animations)
│   └── not-found.tsx
│
├── components/
│   ├── layout/
│   │   └── MobileLayout.tsx        (Phone frame + tab nav)
│   └── ui/                         (Shadcn/UI - Button, Input, etc.)
│
├── lib/
│   ├── utils.ts                    (cn() function for Tailwind merge)
│   └── queryClient.ts              (React Query config)
│
├── App.tsx                         (Router setup with all 5 routes)
├── index.css                       (Shooting star keyframes + globals)
└── main.tsx                        (React entry point)
```

---

## 🎬 Animation Keyframes

### Shooting Star (CSS)

```css
@keyframes shootingStar {
  0% {
    transform: translateX(-200px) translateY(-200px) scaleX(1);
    opacity: 1;
  }
  100% {
    transform: translateX(600px) translateY(600px) scaleX(0);
    opacity: 0;
  }
}

@keyframes shootingStarReverse {
  0% {
    transform: translateX(200px) translateY(-200px) scaleX(1);
    opacity: 1;
  }
  100% {
    transform: translateX(-600px) translateY(600px) scaleX(0);
    opacity: 0;
  }
}
```

### Framer Motion Examples

**Logo Animation:**
```typescript
animate={{ 
  rotate: [0, 5, -5, 0],
  y: [0, -10, 0]
}}
transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
```

**Title Glow:**
```typescript
animate={{ 
  textShadow: [
    "0 2px 0px rgba(124, 58, 237, 1)",
    "0 4px 10px rgba(124, 58, 237, 0.8)",
    "0 2px 0px rgba(124, 58, 237, 1)"
  ]
}}
transition={{ duration: 3, repeat: Infinity }}
```

**Staggered Menu:**
```typescript
variants={{
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.2,
    },
  },
}}
```

**Genre Bar Animation:**
```typescript
initial={{ width: 0 }}
animate={{ width: `${genre.value}%` }}
transition={{ delay: 0.7 + (i * 0.05), duration: 0.8 }}
```

**Rating Stars:**
```typescript
initial={{ opacity: 0, scale: 0 }}
animate={{ opacity: 1, scale: 1 }}
transition={{ delay: 0.8 + (i * 0.1) }}
```

---

## 🎨 Design Decisions

### Why Cosmic Theme?

1. **Audio Visualization:** Space metaphors (DNA, energy) align with music analysis concepts
2. **Modern Appeal:** Neon colors on dark background feel premium and tech-forward
3. **Brand:** Aligns with Antidote's "potion bottle with stars" logo
4. **Contrast:** High contrast ensures accessibility while maintaining aesthetics

### Why Pixel Font (Press Start 2P)?

1. **Retro-futurism:** Combines 80s nostalgia with modern tech feel
2. **Brand Recognition:** Makes title instantly recognizable
3. **Hierarchy:** Used sparingly (headers only) for impact

### Why Framer Motion?

1. **Fine-grained control:** Spring physics, stagger children, tap animations
2. **Performance:** GPU-accelerated transforms
3. **Developer experience:** Declarative syntax matches React patterns

### Why Mobile Frame?

1. **Realistic preview:** Users see exactly how app looks on device
2. **Design constraint:** Enforces mobile-first thinking
3. **Professional presentation:** Looks polished in demos

### New Sections Rationale

**Personality Decoded:**
- Humanizes data analysis
- Gives users emotional context for their music taste
- Builds connection with app

**Genre Distribution:**
- Shows visual breakdown of playlist composition
- Helps users understand diversity
- Animated bars create engagement

**Music Decision Assistant:**
- Addresses both auth and guest users
- Provides actionable suggestions
- Bridges gap between analysis and curation

**Battle Results Redesign:**
- Comprehensive comparison view
- Interactive track selection
- Merged audio DNA visualization for deeper insights

---

## 📖 How to Use This Documentation

1. **For developers:** Reference component specs to understand expected props/behaviors
2. **For designers:** Review wireframes and animation details to maintain consistency
3. **For QA:** Use animation timings and interaction specs to verify behavior
4. **For demos:** Screenshot pages with different content to showcase variations

---

**Last Updated:** December 24, 2025  
**Version:** 2.1.0 (Major Update - Added Decision Assistant, Enhanced Analysis, Redesigned Battle)  
**Maintained By:** Design Engineering Team
