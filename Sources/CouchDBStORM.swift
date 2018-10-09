//
//  CouchDBStORM.swift
//  CouchDBStORM
//
//  Created by Jonathan Guthrie on 2016-10-03.
//
//

import StORM
import PerfectCouchDB
import PerfectLogger

/// CouchDBConnection sets the connection parameters for the CouchDB Server access
/// Usage: 
/// CouchDBConnection.host = "XXXXXX"
/// CouchDBConnection.username = "XXXXXX"
/// CouchDBConnection.password = "XXXXXX"
/// CouchDBConnection.port = 5984
/// CouchDBConnection.ssl = true
public struct CouchDBConnection {

	public static var host: String		= "localhost"
	public static var username: String	= ""
	public static var password: String	= ""
	public static var port: Int			= 5984
	public static var ssl: Bool			= false

	private init(){}

}

/// A "superclass" that is meant to be inherited from by oject classes.
/// Provides ORM structre.
open class CouchDBStORM: StORM, StORMProtocol {

	/// Document revision in CouchDB
	public var _rev = ""

	/// Database object that the child object relates to on the CouchDB server.
	/// Defined as "open" as it is meant to be overridden by the child class.
	open func database() -> String {
		let m = Mirror(reflecting: self)
		return ("\(m.subjectType)").lowercased()
	}

	/// Base initializer method.
	override public init() {
		super.init()
	}

	private func printDebug(_ statement: String, _ params: [String]) {
		if StORMDebug.active { print("StORM Debug: \(statement) : \(params.joined(separator: ", "))") }
	}

	/// Populates a CouchDB object with the required authentication and connector information.
	/// Returns the new CouchDB Object.
	public func setupObject(_ setDatabase: Bool = true) -> CouchDB {
		let obj = CouchDB()
		obj.authentication = CouchDBAuthentication(CouchDBConnection.username, CouchDBConnection.password, auth: .basic)
		obj.connector.host = CouchDBConnection.host
		obj.connector.port = CouchDBConnection.port
		obj.connector.ssl = CouchDBConnection.ssl
		if setDatabase == true { obj.database = database() }
		return obj
	}

	/// Generic "to" function
	/// Defined as "open" as it is meant to be overridden by the child class.
	///
	/// Sample usage:
	///		id				= this.data["id"] as? Int ?? 0
	///		firstname		= this.data["firstname"] as? String ?? ""
	///		lastname		= this.data["lastname"] as? String ?? ""
	///		email			= this.data["email"] as? String ?? ""
	open func to(_ this: StORMRow) {
	}

	/// Generic "makeRow" function
	/// Defined as "open" as it is meant to be overridden by the child class.
	open func makeRow() {
		guard self.results.rows.count > 0 else {
			return
		}
		self.to(self.results.rows[0])
	}



	/// Standard "Save" function.
	/// Designed as "open" so it can be overriden and customized.
	/// Takes an optional "rev" parameter which is the document revision to be used. If empty the object's stored _rev property is used.
	/// If an ID has been defined, save() will perform an update, otherwise a new document is created.
	/// On error can throw a StORMError error.
	open func save(rev: String = "") throws {
		let db = setupObject()
		if !rev.isEmpty { _rev = rev }
		do {
			if keyIsEmpty() {
				let (code, _) = try db.addDoc(doc: try asDataDict(1).jsonEncodedString())
				if .created != code {
					LogFile.critical("CouchDB Doc Save(set) code error \(code)")
					throw StORMError.error("CouchDB Doc Save(set) code error \(code)")
				}
			} else {
				let (_, idval) = firstAsKey()
				let (_, _) = try db.update(docid: idval as! String, doc: asDataDict(1), rev: _rev)
			}
		} catch {
			throw StORMError.error("\(error)")
		}
	}


	/// Alternate "Save" function.
	/// In addition to setting the revision, will use the supplied "set" to assign or otherwise process the returned id.
	/// Designed as "open" so it can be overriden and customized.
	/// Takes an optional "rev" parameter which is the document revision to be used. If empty the object's stored _rev property is used.
	/// If an ID has been defined, save() will perform an updae, otherwise a new document is created.
	/// On error can throw a StORMError error.
	open func save(rev: String = "", set: (_ id: String)->Void) throws {
		let db = setupObject()
		if !rev.isEmpty { _rev = rev }
		do {
			if keyIsEmpty() {
				let (code, response) = try db.addDoc(doc: try asDataDict(1).jsonEncodedString())
				if .created != code {
					LogFile.critical("CouchDB Doc Save(set) code error \(code)")
					throw StORMError.error("CouchDB Doc Save(set) code error \(code)")
				}
				let setId = response["id"] as! String
				_rev = response["rev"] as! String
				set(setId)
			} else {
				let (_, idval) = firstAsKey()
				let (code, response) = try db.update(docid: idval as! String, doc: asDataDict(1), rev: _rev)
				if .created != code {
					LogFile.critical("CouchDB Doc Update Save(set) code error \(code)")
					throw StORMError.error("CouchDB Doc Save(set) Update code error \(code)")
				}
				let setId = response["id"] as! String
				_rev = response["rev"] as! String
				set(setId)
			}
		} catch {
			throw StORMError.error("\(error)")
		}
	}

	/// Unlike the save() methods, create() mandates the addition of a new document, regardless of whether an ID has been set or specified.
	/// The object's revision property is also set once the save has been completed.
	override open func create() throws {
		let db = setupObject()
		do {
			let (_, idval) = firstAsKey()
			let (code, response) = try db.create(docid: idval as! String, doc: asDataDict(1))
			if .created != code {
				LogFile.critical("CouchDB Doc Create code error \(code)")
				throw StORMError.error("CouchDB Doc Create code error \(code)")
			}
			_rev = response["rev"] as! String
		} catch {
			throw StORMError.error("\(error)")
		}
	}



	/// Database Create
	/// Requires CouchDBConnection to be configured, as well as a valid "database" property to have been set in the class
	open func setup() throws {
		let db = setupObject(false)
		// db now inherits directly the auth and connection protocols
		let code = db.databaseCreate(database())
		if .created == code {
			LogFile.info("CouchDB Database \(database()) created.")
		} else if .preconditionFailed != code {
			LogFile.critical("CouchDB Database \(database()) creation experienced \(code), error \(error).")
			throw StORMError.error("CouchDB Database \(database()) creation experienced \(code), error \(error).")
		}
	}
	
}


