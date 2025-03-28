# Models configuration

This guide covers the structure of the models configuration file `config.yaml`. Read more about YAML [here](https://www.yaml.info/).

## Model configuration header 

The model configuration header consists of the following fields:

| Field | Description | Type | Required |
|-------|-------------|------|----------|
| `name` | The name of the model, potentially including the version identifier. | String | Yes |
| `description` | A short description of the model. | String | Yes |
| `author` | The author of the model | String | Yes |
| `roles` | The roles that can use the model. | Array of Strings | Yes |

A simple example of a model configuration header is shown below:

```yaml
name: MyModel-v1
description: A model for predicting the weather
author: John Doe
roles:
  - user

# Other fields
# ...
```

Upon loading a model, the model configuration header will be validated.
An error will be thrown if the model configuration header is invalid, e.g. if some of the fields are missing or are of the wrong type.