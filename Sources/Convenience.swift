//
//  Convenience.swift
//  PostgresStORM
//
//  Created by Jonathan Guthrie on 2016-10-04.
//
//

import StORM
import PerfectCouchDB

extension CouchDBStORM {

	/// Deletes one row, with an id
	/// Presumes first property in class is the id.
	public func delete() throws {
		let db = setupObject()
		let (_, idval) = firstAsKey()
		if _rev.isEmpty {
			self.error = StORMError.error("No revision specified.")
			throw error
		}
		if (idval as! String).isEmpty {
			self.error = StORMError.error("No id specified.")
			throw error
		}
		do {
			let (code, _) = try db.delete(docid: idval as! String, rev: _rev)
			if code != .ok && code != .accepted {
				self.error = StORMError.error("Error: \(code)")
				throw error
			}
		} catch {
			self.error = StORMError.error("\(error)")
			throw error
		}
	}


	public func get(_ id: String) throws {
		let db = setupObject()
		do {
			let (code, response) = try db.get(docid: id)
			if code != .ok && code != .notModified && code != .notFound {
				self.error = StORMError.error("Error: \(code)")
				throw error
			}
			if code == .notFound {
				return
			}
			// convert response into object
			try processResponse(response)
		} catch {

			self.error = StORMError.error("\(error)")
			throw error
		}
	}

	public func get() throws {
		let (_, idval) = firstAsKey()
		do {
			try get(idval as! String)
		} catch {
			throw error
		}
	}

	// The major diff to the CouchDB method is it pours the data INTO the object
	public func find(_ data: [String: Any], cursor: StORMCursor = StORMCursor()) throws {
		let db = setupObject()
		let findObject = CouchDBQuery()
		findObject.selector = data
		findObject.limit = cursor.limit
		findObject.skip = cursor.offset

		do {
			let (code, response) = try db.find(queryParams: findObject)
			if code != .ok {
				self.error = StORMError.error("Error: \(code)")
				throw error
			}
			try processResponse(response)
		} catch {
			throw error
		}

	}

	private func processResponse(_ response: [String:Any]) throws {
		do {
			try results.rows = parseRows(response)
			results.cursorData.totalRecords = results.rows.count
			if results.cursorData.totalRecords == 1 { makeRow() }
		} catch {
			throw error
		}
	}
}
