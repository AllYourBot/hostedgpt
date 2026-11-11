# Deliberate duplication in settings

## Standard Rails scaffolding

The new and index templates and the test controller actions follow the scaffold shape. Sharing them would add indirection without much benefit.

```parallel
views/settings/language_models/new.html.erb
views/settings/api_services/new.html.erb
views/settings/connectors/new.html.erb
views/documents/new.html.erb
```

```parallel
Settings::LanguageModelsController#test
Settings::APIServicesController#test
```

```parallel
views/settings/assistants/index.html.erb
views/settings/api_services/index.html.erb
views/settings/connectors/index.html.erb
```
