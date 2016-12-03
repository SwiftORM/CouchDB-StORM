# CouchDB-StORM

CouchDB-StORM is the CouchDB module for StORM - a Swift ORM.

It aims to be easy to use, but flexible. Drawing on previous experiences, whether they be good, bad or ugly, of other ORM's, I have tried to build a system that allows you write great code without worrying about the details of how to interact with the database.

Other database wrappers will be available shortly. They will all use the StORM base, and provide as much consistency between datasources as possible.

StORM is built on top of [Perfect](https://github.com/PerfectlySoft/Perfect) - the most mature of the Server Side Swift platforms.

### What does it do?

* Abstracts the database layer from your code.
* Provides a way of adding save, delete, find to your Swift classes
* Gives you access to more powerful find, create, update and delete.
* Maps result sets to your classes

