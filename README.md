# CRUD-O
A lightweight, 0-boilerplate and flexible CRUD framework built around Bloc and Flutter.

## Getting Started
You will basically be writing four files foreach model you want to interact with from the backend:
- A [Resource](#resources) file
- A [Repository](#repository) file
- A [Factory](#factory) file
- A [Serializer](#serializer) file

## Resource
Resources are the core of the CRUD-O framework. You should create a resource foreach 
model you need to interact with from the backend. A resource is a class that extends the
`Resource`. It holds the [Repository](#repository) that will be used to interact with the
backend and...

## Repository
A Repository is a class that extends the `ResourceRepository`. It is responsible for
interacting with the backend. It's created with simplicity and readability in mind so
the only thing you need to provide is the path to the endpoint you want to interact with,
the standard methods to retrieve and send data to the backend are already implemented.
You can extend the repository to add custom methods to interact with the backend.

## Factory
A Factory is a class that extends the `ResourceFactory`. It is responsible for creating
new instances of objects for these scenarios:
- `createFromJson`: When deserializing a model from a json object
- `createFromJsonList`: When deserializing a list of models from a json object
- `createFromFormData`: When deserializing a model from a form data

A special method `createFromMap` is present. This is used as a fallback for the other methods
when they are not implemented. If your factories are all equal you can just override this method
instead of all the others. 

> Note: If you don't provide a `createFromMap` and you don't implement the other methods, the factory
> will throw an error when trying to deserialize a model in the scenarios mentioned above.


## Serializer
A Serializer is a class that extends the `ResourceSerializer`. It is basically the opposite of the
`Factory`. It is responsible for serializing a model into a map object for these scenarios:
- `serializeToJson`: When serializing a model to a json object to send over the network
- `serializeToView`: When serializing a model to a key-value map to display in the view page
- `serializeToFormData`: When serializing a model to display in a form page
- `serializeToCells`: When serializing a model to cells for the table page

## Components
With crud-o you will instantly get a set of pages ready to interact with your backend.
This package will provide you:
- A `TablePage` to list all the items from the backend
- A `FormPage` to create and update items
- A `ViewPage` to view the details of an item

### TablePage
The `TablePage` is a page that lists all the items from the backend. You can add a search bar,
filters and custom actions to interact with the items.

### FormPage
The `FormPage` is a page that allows you to create and update items from the backend.
This form page has validation built-in and will automatically highlight the fields that
did not pass the validation, both on the client and on the server.

When the form page updates or creates an item successfully, when popped will return `true` in the 
action that triggered the page so that the table or the view page that fired the action will know
that it needs to refresh the data.

### ViewPage
The `ViewPage` is a page that displays the details of an item from the backend.


## Auth
The auth mechanism is set up using the `CrudoAuthWrapper` widget. This widget will wrap your
application and will provide the auth context to all the pages that need it. You can also provide
a custom Future `authCheck` to check if the user is logged in or not, then you can pass the
`loggedIn` and `loggedOut` widgets to show the user the login page or the main page.

The `CrudoAuth` will also provide a `login` and `logout` extension on the BuildContext so
you can easily call these methods from anywhere in your app to login or logout the user.
