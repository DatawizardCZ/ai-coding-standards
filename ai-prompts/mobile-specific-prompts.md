# Mobile-Specific AI Prompts

## 📱 Mobile-First Component Creation

### Mobile Modal Component
```
Create a [ModalName]Modal component with mobile-first responsive design:

**Mobile Behavior:**
- Full-screen overlay with rounded top corners
- Slide up animation from bottom
- Drag indicator at top for dismissal
- Touch-friendly close button (44px minimum)
- Larger padding and text sizes

**Desktop Behavior:**
- Centered modal with max-width
- Standard rounded corners
- Backdrop click to close
- Hover states for interactions

**Technical Requirements:**
- Follow our modal template structure
- Use mobile-first Tailwind classes (base mobile, md: desktop)
- Implement touch gesture support
- Include proper focus management
- Use our color system and spacing standards
```

### Mobile Form Component
```
Create a [FormName]Form component optimized for mobile:

**Mobile Optimizations:**
- Larger input fields (py-4 on mobile, py-2 on desktop)
- Touch-friendly buttons (min-h-[48px])
- Proper keyboard support (inputmode, autocomplete)
- Error messages with adequate spacing
- Single-column layout on mobile

**Responsive Behavior:**
- Stack form fields vertically on mobile
- Side-by-side layout on tablet/desktop where appropriate
- Full-width buttons on mobile, auto-width on desktop
- Larger touch targets throughout

**Use our form patterns and mobile-responsive classes**
```

### Mobile Data Display
```
Create a [ComponentName] data display component with mobile optimization:

**Mobile Layout:**
- Single column card grid on mobile
- Larger touch targets for interactive elements
- Simplified information hierarchy
- Bottom sheet or full-screen modals for details

**Desktop Enhancement:**
- Multi-column grid layout
- Hover states and tooltips
- Inline editing capabilities
- Sidebar or popover details

**Follow our responsive grid patterns and touch-target guidelines**
```

## 🎛️ Mobile Interaction Prompts

### Swipe Gesture Component
```
Create a swipeable [ComponentName] with gesture support:

**Swipe Actions:**
- Left swipe: [specify action, e.g., delete, archive]
- Right swipe: [specify action, e.g., complete, approve]
- Visual feedback during swipe
- Haptic feedback on supported devices

**Implementation:**
- Use touch events (touchstart, touchmove, touchend)
- Threshold of 100px for action trigger
- Smooth animations with CSS transforms
- Fallback buttons for non-touch devices

**Include proper accessibility alternatives for non-gesture users**
```

### Pull-to-Refresh List
```
Create a [ListName] component with pull-to-refresh:

**Mobile Features:**
- Pull-to-refresh gesture at top of list
- Loading indicator during refresh
- Smooth animations and transitions
- Proper scroll handling

**Performance:**
- Virtual scrolling for large lists
- Lazy loading of list items
- Optimized re-renders
- Image lazy loading

**Follow our list component patterns and loading state designs**
```

## 📐 Responsive Layout Prompts

### Mobile Navigation
```
Create responsive navigation following our mobile patterns:

**Mobile (< 768px):**
- Bottom tab navigation
- 4-5 main navigation items
- Icon + label format
- Fixed positioning
- Active state indicators

**Desktop (≥ 768px):**
- Sidebar navigation
- Expanded labels and descriptions
- Hover states
- Collapsible sections

**Use our navigation color scheme and spacing standards**
```

### Responsive Modal Sizes
```
Create modal component with responsive sizing:

**Size Variants:**
- sm: Full-screen mobile, 400px desktop
- md: Full-screen mobile, 600px desktop  
- lg: Full-screen mobile, 800px desktop
- full: Full-screen on all devices

**Mobile Adaptations:**
- Slide up from bottom animation
- Drag handle for dismissal
- Safe area padding for notched devices
- Proper keyboard handling

**Follow our modal template and responsive patterns**
```

## 🎨 Mobile Styling Prompts

### Touch-Friendly Styling
```
Style this component for optimal mobile experience:

**Touch Targets:**
- Minimum 44px × 44px for all interactive elements
- 8px minimum spacing between touch targets
- Visual feedback on touch (press states)
- Clear focus indicators for keyboard users

**Typography:**
- Minimum 16px text size on mobile
- Adequate line height (1.5 minimum)
- Sufficient contrast ratios
- Responsive text scaling

**Use our mobile-specific utility classes and color system**
```

### Performance Optimization
```
Optimize this component for mobile performance:

**Loading Strategies:**
- Lazy load non-critical components
- Progressive image loading
- Code splitting for heavy features
- Efficient bundle sizing

**Animations:**
- Use CSS transforms over position changes
- Limit concurrent animations
- Respect prefers-reduced-motion
- 60fps target for smooth interactions

**Memory Management:**
- Proper cleanup of event listeners
- Virtualization for large lists
- Image optimization and caching
- Efficient state updates
```

## 🧪 Mobile Testing Prompts

### Device Testing
```
Ensure this component works across mobile devices:

**Testing Checklist:**
- iOS Safari (iPhone SE, iPhone 14, iPad)
- Android Chrome (various screen sizes)
- Touch interactions and gestures
- Keyboard behavior and inputs
- Orientation changes (portrait/landscape)

**Performance Testing:**
- Load time on 3G connections
- Memory usage on older devices
- Battery impact assessment
- Accessibility with screen readers

**Validation Steps:**
- All touch targets meet size requirements
- Text remains readable at all sizes
- Forms work with mobile keyboards
- Navigation accessible with thumb reach
```

## 🔄 Mobile-Specific Corrections

### Touch Target Fixes
```
Update this component to meet mobile touch requirements:
- Increase button/link sizes to minimum 44px × 44px
- Add adequate spacing between interactive elements
- Ensure proper visual feedback on touch
- Include focus indicators for keyboard navigation
- Use our touch-target utility classes
```

### Responsive Layout Fixes
```
Fix responsive behavior for mobile devices:
- Apply mobile-first CSS approach (base styles for mobile)
- Use proper Tailwind responsive prefixes (sm:, md:, lg:)
- Ensure content fits in mobile viewport
- Stack elements vertically on small screens
- Implement proper modal/overlay behavior
```

### Mobile Performance Fixes
```
Optimize this component for mobile performance:
- Implement lazy loading for images and components
- Add proper loading states
- Optimize animations for 60fps
- Reduce bundle size with code splitting
- Add proper cleanup for memory management
```

These prompts ensure your components provide excellent mobile experiences while maintaining our design standards and technical requirements.
