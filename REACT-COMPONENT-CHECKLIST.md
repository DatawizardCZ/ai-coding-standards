# React Component Development Checklist

## ⚠️ Rules of Hooks - CRITICAL

React hooks **MUST** always be called in the same order. Follow this pattern:

### ✅ Correct Pattern:

```typescript
function Component({ data, onAction }) {
  // ✅ 1. ALL HOOKS FIRST (always at the top, never conditional)
  const [state, setState] = useState(initialValue);
  const [loading, setLoading] = useState(false);

  // ✅ 2. ALL useMemo/useCallback (with safe checks inside)
  const computed = useMemo(() => {
    if (!data) return defaultValue; // ✅ Condition INSIDE hook
    return transform(data);
  }, [data]);

  // ✅ 3. ALL useEffect
  useEffect(() => {
    // effect code
  }, [dependencies]);

  // ✅ 4. Event handlers and other functions
  const handleClick = () => {
    // handler code
  };

  // ✅ 5. Early returns AFTER all hooks
  if (!data) {
    return <EmptyState />;  // ✅ OK - after all hooks
  }

  if (loading) {
    return <Loading />;  // ✅ OK - after all hooks
  }

  // ✅ 6. Main render
  return (
    <div>{/* component UI */}</div>
  );
}
```

### ❌ Common Mistakes:

```typescript
function Component({ data }) {
  const [state, setState] = useState();

  // ❌ WRONG - early return before hooks
  if (!data) return null;

  // ❌ This hook will not always be called!
  const computed = useMemo(() => transform(data), [data]);

  return <div>{computed}</div>;
}
```

```typescript
function Component({ condition }) {
  const [state, setState] = useState();

  // ❌ WRONG - conditional hook
  if (condition) {
    const value = useMemo(() => compute(), []); // ❌ Hook in condition!
  }

  return <div>{state}</div>;
}
```

## 📋 Component Development Workflow

### When writing a new component:

1. **Start with the interface:**
   ```typescript
   interface ComponentProps {
     data: DataType;
     onAction: () => void;
   }
   ```

2. **Write ALL hooks first:**
   ```typescript
   export function Component({ data, onAction }: ComponentProps) {
     // Write ALL useState
     const [state1, setState1] = useState();
     const [state2, setState2] = useState();

     // Write ALL useMemo/useCallback
     const computed = useMemo(() => ..., []);

     // Write ALL useEffect
     useEffect(() => ..., []);

     // TODO: Add validation and render logic below
   }
   ```

3. **Add validation/early returns:**
   ```typescript
   // Only NOW add early returns
   if (!data) return <EmptyState />;
   ```

4. **Add render logic:**
   ```typescript
   return <div>...</div>;
   ```

## 🔍 Before Committing:

Run ESLint to catch hooks violations:
```bash
npx eslint src/path/to/component.tsx
```

## 🎯 Key Rules:

1. ✅ **All hooks at the top** - before any conditional logic
2. ✅ **Same hooks order every render** - no conditionals around hooks
3. ✅ **Conditions inside hooks** - not around them
4. ✅ **Early returns after hooks** - never before
5. ✅ **Optional chaining in hooks** - use `data?.prop` in useMemo dependencies

## 📚 Resources:

- [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks)
- [ESLint Plugin React Hooks](https://www.npmjs.com/package/eslint-plugin-react-hooks)
