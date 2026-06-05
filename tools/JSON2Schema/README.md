# JSON2Schema

`JSON2Schema` is a **Data-to-Schema** generator that infers a valid, structured JSON Schema document by analyzing one or multiple JSON instance files. It simplifies schema creation by doing the heavy lifting of structure analysis.

## Features

- **Multi-Instance Inference**: Analyzes multiple JSON documents to determine which fields are optional, which are required, and the unions of different types.
- **Smart Format Detection**: Inspects string values and automatically applies format validations (e.g. `email`, `uuid`, `ipv4`, `date-time`).
- **Array Normalization**: Analyzes array elements to check if they are homogeneous (mapping to single `items`) or tuple-based (mapping to `prefixItems`).
- **Numeric Bounds Inference**: Optionally infers range constraints (`minimum` and `maximum`) based on the min/max values found in the data.
