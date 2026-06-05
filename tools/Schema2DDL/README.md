# Schema2DDL

`Schema2DDL` is a database utility that translates JSON Schema definitions into relational database SQL DDL (Data Definition Language) scripts. It enables automatic database table creation from schema models.

## Features

- **Database Engine Support**: Generates engine-specific SQL scripts (Firebird, PostgreSQL, MySQL, MS SQL, SQLite).
- **Relational Normalization**: Automatically splits arrays and nested object hierarchies into secondary tables, inserting foreign key relationships.
- **Constraint Translation**: Maps schema constraints like `minimum`/`maximum` and `maxLength` into equivalent SQL constraints (`CHECK`, `VARCHAR(N)`).
- **Index Generation**: Automatically generates indices for primary/foreign keys and fields marked for quick search in schema annotations.
