# Deliberate duplication in settings

## Standard Rails scaffolding

The new templates and the test controller actions follow the scaffold shape. Sharing them would add indirection without much benefit.

```parallel
Settings::LanguageModelsController#test
Settings::APIServicesController#test
```
