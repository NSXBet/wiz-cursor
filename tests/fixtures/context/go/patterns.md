---
description: Go-specific patterns and best practices
tags: [patterns, go, golang]
languages: [go]
applies_to: [planning, execution]
---

## description: Go-specific patterns and best practices tags: [patterns, go, golang] languages: [go] applies_to: [planning, execution]

# Go Patterns

## Error Handling

Always handle errors explicitly:

```go
if err != nil {
    return fmt.Errorf("context: %w", err)
}
```

## Testing

Use table-driven tests:

```go
func TestFunction(t *testing.T) {
    tests := []struct {
        name string
        input string
        want string
    }{
        {"test1", "input", "expected"},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Function(tt.input)
            if got != tt.want {
                t.Errorf("got %q, want %q", got, tt.want)
            }
        })
    }
}
```

## Project Structure

Follow standard Go project layout:

- `cmd/` - Application entrypoints
- `internal/` - Private application code
- `pkg/` - Public library code
- `test/` - Test data and fixtures
