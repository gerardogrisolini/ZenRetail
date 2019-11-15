//
//  TagGroupRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 07/11/17.
//

import NIO
import ZenPostgres

struct TagGroupRepository : TagGroupProtocol {
    
    func getAll() -> EventLoopFuture<[TagGroup]> {
        return TagGroup().query()
    }
    
    func getAllAndValues() -> EventLoopFuture<[TagGroup]> {
        let tagGroup = TagGroup()
        let sql = tagGroup.querySQL(
            orderby: ["TagGroup.tagGroupId", "TagValue.tagValueId"],
            joins: [
                DataSourceJoin(
                    table: "TagValue",
                    onCondition: "TagGroup.tagGroupId = TagValue.tagGroupId",
                    direction: .LEFT
                )
            ]
        )
        
        return tagGroup.sqlRowsAsync(sql).map { rows -> [TagGroup] in
            let groups = Dictionary(grouping: rows) { row in
                row.column("tagGroupId")!.int!
            }
            
            var result = [TagGroup]()
            for group in groups.sorted(by: { $0.key < $1.key }) {
                let g = TagGroup()
                g.decode(row: group.value.first!)
                for att in group.value {
                    let v = TagValue()
                    v.decode(row: att)
                    g._values.append(v)
                }
                result.append(g)
            }
            return result
        }
    }

    func get(id: Int) -> EventLoopFuture<TagGroup> {
        let item = TagGroup()
        return item.get(id).map { () -> TagGroup in
            item
        }
    }
    
    func getValues(id: Int) -> EventLoopFuture<[TagValue]> {
        return TagValue().query(whereclause: "tagGroupId = $1", params: [id])
    }
    
    func add(item: TagGroup) -> EventLoopFuture<Int> {
        item.tagGroupCreated = Int.now()
        item.tagGroupUpdated = Int.now()
        return item.save().map { id -> Int in
            item.tagGroupId = id as! Int
            return item.tagGroupId
        }
    }
    
    func update(id: Int, item: TagGroup) -> EventLoopFuture<Bool> {
      item.tagGroupUpdated = Int.now()
        return item.save().map { id -> Bool in
            id as! Int > 0
        }
    }
    
    func delete(id: Int) -> EventLoopFuture<Bool> {
        return ZenPostgres.pool.connect().flatMap { connection -> EventLoopFuture<Bool> in
            defer { connection.disconnect() }
            return TagValue(connection: connection).delete(key: "tagId", value: id).flatMap { id -> EventLoopFuture<Bool> in
                return TagGroup(connection: connection).delete(id)
            }
        }
    }
}

