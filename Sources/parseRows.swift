//
//  parseRows.swift
//  PostgresStORM
//
//  Created by Jonathan Guthrie on 2016-10-06.
//
//

import StORM
import PerfectCouchDB
import PerfectLib
import Foundation

/// Supplies the parseRows method extending the main CouchDBStORM class.
extension CouchDBStORM {

	/// parseRows takes the [String:Any] result and returns an array of StormRows 
	public func parseRows(_ result: [String:Any]) throws -> [StORMRow] {

		var resultRows = [StORMRow]()

		if let docs = result["docs"] {
			// multiple rows
			for i in docs as! [Any] {
				let thisRow = StORMRow()
				thisRow.data = i as! Dictionary<String, Any>
				resultRows.append(thisRow)
			}
			return resultRows
		}
		if let _ = result["_id"] {
			// single row
			let thisRow = StORMRow()
			thisRow.data = result
			resultRows.append(thisRow)
			return resultRows
		}
		return resultRows
	}
}
