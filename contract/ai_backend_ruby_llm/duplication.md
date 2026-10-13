# Deliberate duplication in the RubyLLM transport

## The chat paths carry the same mapped-error rescues on purpose

Both chat entry points rescue the same RubyLLM error lists at the `chat.complete` boundary and raise through `mapped_error`. The RubyLLM migration plan pins this shape: both methods carry the complete-level rescues because the gem raises its error hierarchy in its HTTP layer, outside the per-chunk handler — this is the defensive second layer, not accidental. When the error format changes, change `mapped_error`, not these stanzas.

```parallel
AIBackend::RubyLLM#get_oneoff_message
AIBackend::RubyLLM#stream_next_conversation_message
```
