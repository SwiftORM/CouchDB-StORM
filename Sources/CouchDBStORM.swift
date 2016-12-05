//
//  PostgreStORM.swift
//  PostgresSTORM
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


open class CouchDBStORM: StORM, StORMProtocol {

	public var _rev = ""


	open func database() -> String {
		return "unset"
	}

	override public init() {
		super.init()
	}

	private func printDebug(_ statement: String, _ params: [String]) {
		if StORMdebug { print("StORM Debug: \(statement) : \(params.joined(separator: ", "))") }
	}

	public func setupObject(_ setDatabase: Bool = true) -> CouchDB {
		let obj = CouchDB()
		obj.authentication = CouchDBAuthentication(CouchDBConnection.username, CouchDBConnection.password, auth: .basic)
		obj.connector.host = CouchDBConnection.host
		obj.connector.port = CouchDBConnection.port
		obj.connector.ssl = CouchDBConnection.ssl
		if setDatabase == true { obj.database = database() }
		return obj
	}
//	// Internal function which executes statements, with parameter binding
//	// Returns raw result
//	@discardableResult
//	func exec(_ statement: String, params: [String]) throws -> PGResult {
//		let thisConnection = PostgresConnect(
//			host:		PostgresConnector.host,
//			username:	PostgresConnector.username,
//			password:	PostgresConnector.password,
//			database:	PostgresConnector.database,
//			port:		PostgresConnector.port
//		)
//
//		thisConnection.open()
//		thisConnection.statement = statement
//
//		printDebug(statement, params)
//		let result = thisConnection.server.exec(statement: statement, params: params)
//
//		// set exec message
//		errorMsg = thisConnection.server.errorMessage().trimmingCharacters(in: .whitespacesAndNewlines)
//		if StORMdebug { LogFile.info("Error msg: \(errorMsg)", logFile: "./StORMlog.txt") }
//		if isError() {
//			thisConnection.server.close()
//			throw StORMError.error(errorMsg)
//		}
//		thisConnection.server.close()
//		return result
//	}
//
//	// Internal function which executes statements, with parameter binding
//	// Returns a processed row set
//	@discardableResult
//	func execRows(_ statement: String, params: [String]) throws -> [StORMRow] {
//		let thisConnection = PostgresConnect(
//			host:		PostgresConnector.host,
//			username:	PostgresConnector.username,
//			password:	PostgresConnector.password,
//			database:	PostgresConnector.database,
//			port:		PostgresConnector.port
//		)
//
//		thisConnection.open()
//		thisConnection.statement = statement
//
//		printDebug(statement, params)
//		let result = thisConnection.server.exec(statement: statement, params: params)
//
//		// set exec message
//		errorMsg = thisConnection.server.errorMessage().trimmingCharacters(in: .whitespacesAndNewlines)
//		if StORMdebug { LogFile.info("Error msg: \(errorMsg)", logFile: "./StORMlog.txt") }
//		if isError() {
//			thisConnection.server.close()
//			throw StORMError.error(errorMsg)
//		}
//
//		let resultRows = parseRows(result)
//		//		result.clear()
//		thisConnection.server.close()
//		return resultRows
//	}


//	func isError() -> Bool {
//		if errorMsg.contains(string: "ERROR") {
//			print(errorMsg)
//			return true
//		}
//		return false
//	}

	open func to(_ this: StORMRow) {
		//		id				= this.data["id"] as! Int
		//		firstname		= this.data["firstname"] as! String
		//		lastname		= this.data["lastname"] as! String
		//		email			= this.data["email"] as! String
	}

	open func makeRow() {
		guard self.results.rows.count > 0 else {
			return
		}
		self.to(self.results.rows[0])
	}



	@discardableResult
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
//				LogFile.info("CouchDB Doc Save() code \(code)")
//				LogFile.info("CouchDB Doc Save() response \(response)")
			} else {
				let (_, idval) = firstAsKey()
				let (_, _) = try db.update(docid: idval as! String, doc: asDataDict(1), rev: _rev)
//				LogFile.info("CouchDB Doc Update Save() code \(code)")
//				LogFile.info("CouchDB Doc Update Save() response \(response)")
			}
		} catch {
			throw StORMError.error("\(error)")
		}
	}
	@discardableResult
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

	@discardableResult
	override open func create() throws {
		let db = setupObject()
		do {
			let (_, idval) = firstAsKey()
//			LogFile.info("id: \(idval)")
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
	@discardableResult
	open func setup() throws {
		let db = setupObject(false)

//		LogFile.info("\(CouchDBConnection.host), \(CouchDBConnection.port)")

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


