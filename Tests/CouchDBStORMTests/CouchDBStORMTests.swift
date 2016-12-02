import XCTest
import PerfectLib
import Foundation
import StORM
import PerfectCouchDB
import SwiftRandom
@testable import CouchDBStORM



class User: CouchDBStORM {
	// NOTE: First param in class should be the ID.
	var id				: String = ""
	var firstname		: String = ""
	var lastname		: String = ""
	var email			: String = ""


	override open func database() -> String {
		return "users"
	}

	override func to(_ this: StORMRow) {
		id				= this.data["_id"] as? String ?? ""
		firstname		= this.data["firstname"] as? String ?? ""
		lastname		= this.data["lastname"] as? String ?? ""
		email			= this.data["email"] as? String ?? ""
	}

	func rows() -> [User] {
		var rows = [User]()
		for i in 0..<self.results.rows.count {
			let row = User()
			row.to(self.results.rows[i])
			rows.append(row)
		}
		return rows
	}
//	override func makeRow() {
//		self.to(self.results.rows[0])
//	}
}


class CouchDBStORMTests: XCTestCase {


	override func setUp() {
		super.setUp()

		CouchDBConnection.host = "localhost"
		CouchDBConnection.username = "perfect"
		CouchDBConnection.password = "perfect"

	}


	/* =============================================================================================
	Create DB
	============================================================================================= */
	func testCreateDB() {
		let obj = User()
		do {
			try obj.setup()
		} catch {
			XCTFail("\(error)")
		}
	}

	/* =============================================================================================
	Save - New
	============================================================================================= */
	func testSaveNew() {
		let obj = User()
		obj.firstname = "X"
		obj.lastname = "Y"

		do {
			try obj.save(){id in obj.id = id }
		} catch {
			XCTFail("\(error)")
		}
		XCTAssert(!obj.id.isEmpty, "Object not saved (new)")
	}


	/* =============================================================================================
	Save - Update
	============================================================================================= */
	func testSaveUpdate() {
		let obj = User()
		obj.firstname = "X"
		obj.lastname = "Y"

		do {
			try obj.save {id in obj.id = id }
			print("id is: \(obj.id), rev: \(obj._rev)")
		} catch {
			XCTFail("\(error)")
		}

		obj.firstname = "A"
		obj.lastname = "B"
		do {
			try obj.save()
			print("update, id is: \(obj.id), rev: \(obj._rev)")
		} catch {
			XCTFail("\(error)")
		}
		print(obj.errorMsg)
		XCTAssert(!obj.id.isEmpty, "Object not saved (update)")
	}

	/* =============================================================================================
	Save - Create
	============================================================================================= */
	func testSaveCreate() {
		// first clean up!

		let obj = User()
		let rand = Randoms.randomAlphaNumericString(length: 12)
		do {
			obj.id			= rand
			obj.firstname	= "Mister"
			obj.lastname	= "PotatoHead"
			obj.email		= "potato@example.com"
			try obj.create()
		} catch {
			XCTFail("\(error)")
		}
		XCTAssert(obj.id == rand, "Object not saved (create)")
	}

	/* =============================================================================================
	Get (with id)
	============================================================================================= */
	func testGetByPassingID() {
		let obj = User()
		//obj.connection = connect    // Use if object was instantiated without connection
		obj.firstname = "X"
		obj.lastname = "Y"

		do {
			try obj.save {id in obj.id = id }
		} catch {
			XCTFail("\(error)")
		}

		let obj2 = User()

		do {
			try obj2.get(obj.id)
		} catch {
			XCTFail("\(error)")
		}
		XCTAssert(obj.id == obj2.id, "Object not the same (id)")
		XCTAssert(obj.firstname == obj2.firstname, "Object not the same (firstname)")
		XCTAssert(obj.lastname == obj2.lastname, "Object not the same (lastname)")
	}


	/* =============================================================================================
	Get (by id set)
	============================================================================================= */
	func testGetByID() {
		let obj = User()
		//obj.connection = connect    // Use if object was instantiated without connection
		obj.firstname = "X"
		obj.lastname = "Y"

		do {
			try obj.save {id in obj.id = id }
		} catch {
			XCTFail("\(error)")
		}

		let obj2 = User()
		obj2.id = obj.id
		
		do {
			try obj2.get()
		} catch {
			XCTFail("\(error)")
		}
		XCTAssert(obj.id == obj2.id, "Object not the same (id)")
		XCTAssert(obj.firstname == obj2.firstname, "Object not the same (firstname)")
		XCTAssert(obj.lastname == obj2.lastname, "Object not the same (lastname)")
	}

//	/* =============================================================================================
//	Get (with id) - integer too large
//		NOT RELEVANT FOR COUCHDB
//	============================================================================================= */
//	func testGetByPassingIDtooLarge() {
//		let obj = User()
//
//		do {
//			try obj.get(874682634789)
//			XCTFail("Should have failed (integer too large)")
//		} catch {
//			print("^ Ignore this error, that is expected and should show 'ERROR:  value \"874682634789\" is out of range for type integer'")
//			// test passes - should have a failure!
//		}
//	}

	/* =============================================================================================
	Get (with id) - no record
	// test get where id does not exist (id)
	============================================================================================= */
	func testGetByPassingIDnoRecord() {
		let obj = User()

		do {
			try obj.get()
			if obj.results.cursorData.totalRecords > 0 {
				XCTFail("Should have failed (no records)")
			}
			XCTFail("Should have failed with notAcceptable")
		} catch {
			// should have failed!
		}
	}


	// test get where id does not exist ()
	/* =============================================================================================
	Get (preset id) - no record
	// test get where id does not exist (id)
	============================================================================================= */
	func testGetBySettingIDnoRecord() {
		let obj = User()
		do {
			try obj.get()
			if obj.results.cursorData.totalRecords > 0 {
				XCTFail("Should have failed (no records)")
			}
			XCTFail("Should have failed (record not found)")
		} catch {
			// test passes - should have a failure!
		}
	}


//	/* =============================================================================================
//	Returning DELETE statement to verify correct form
//	NOT APPLICCABLE FOR NOSQL
//	============================================================================================= */
//	func testCheckDeleteSQL() {
//		let obj = User()
//		XCTAssert(obj.deleteSQL("test", idName: "testid") == "DELETE FROM test WHERE testid = $1", "DeleteSQL statement is not correct")
//
//	}


	/* =============================================================================================
	DELETE
	============================================================================================= */
	func testDelete() {
		let obj = User()
		let rand = Randoms.randomAlphaNumericString(length: 12)
		do {
			obj.id			= rand
			obj.firstname	= "Mister"
			obj.lastname	= "PotatoHead"
			obj.email		= "potato@example.com"
			try obj.create()
		} catch {
			XCTFail("\(error)")
		}
		XCTAssert(obj.id == rand, "Object not saved for delete")
		do {
			try obj.delete()
		} catch {
			XCTFail("\(error)")
		}
	}



	/* =============================================================================================
	Find
	============================================================================================= */
	func testFindZero() {
		let obj = User()

		do {
			try obj.find(["firstname":Randoms.randomAlphaNumericString(length: 12)])
			XCTAssert(obj.results.rows.count == 0, "There was at least one row found. There should be ZERO.")
		} catch {
			XCTFail("Find error: \(obj.error.string())")
		}
	}
	func testFind() {
		let obj = User()
		let rand = Randoms.randomAlphaNumericString(length: 12)
		do {
			obj.id	= rand
			obj.firstname	= rand
			obj.lastname	= "PotatoHead"
			obj.email		= "potato@example.com"
			try obj.create()
		} catch {
			XCTFail("\(error)")
		}


		let objFind = User()

		do {
			try objFind.find(["firstname":rand])
			XCTAssert(objFind.results.rows.count == 1, "There should only be one row found.")
		} catch {
			XCTFail("Find error: \(obj.error.string())")
		}
	}






	static var allTests : [(String, (CouchDBStORMTests) -> () throws -> Void)] {
		return [
			("testCreateDB", testCreateDB),
			("testSaveNew", testSaveNew),
			("testSaveUpdate", testSaveUpdate),
			("testSaveCreate", testSaveCreate),
			("testGetByPassingID", testGetByPassingID),
			("testGetByID", testGetByID),
//			("testGetByPassingIDtooLarge", testGetByPassingIDtooLarge),
			("testGetByPassingIDnoRecord", testGetByPassingIDnoRecord),
			("testGetBySettingIDnoRecord", testGetBySettingIDnoRecord),
//			("testCheckDeleteSQL", testCheckDeleteSQL),
			("testDelete", testDelete),
			("testFind", testFindZero),
			("testFind", testFind)
		]
	}

}
