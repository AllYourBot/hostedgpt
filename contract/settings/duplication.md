# Deliberate duplication in settings

## Standard Rails scaffolding

The new templates and the test controller actions follow the scaffold shape. Sharing them would add indirection without much benefit.

```parallel
views/settings/language_models/new.html.erb
views/settings/api_services/new.html.erb
views/documents/new.html.erb
```

```parallel
Settings::LanguageModelsController#test
Settings::APIServicesController#test
```
