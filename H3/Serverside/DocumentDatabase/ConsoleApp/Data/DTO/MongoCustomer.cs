using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System;
using System.Collections.Generic;
using System.Text;

namespace ConsoleApp.Data.DTO;

public class MongoCustomer
{
    [BsonId] // Fortæller MongoDB at dette er primærnøglen
    [BsonRepresentation(BsonType.String)] // Gemmer din Guid som en læsbar streng
    public Guid Id { get; set; }
    public string Name { get; set; }
    public List<MongoOrder> Orders { get; set; } = new();
}
