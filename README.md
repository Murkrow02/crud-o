# CRUD-O
A lightweight, easy-to-use, and flexible CRUD framework built around Bloc and Flutter.

## Getting Started


## Resources
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

## Actions

