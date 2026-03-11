using ConsoleApp.Data;
using ConsoleApp.Data.DTO;
using Microsoft.EntityFrameworkCore;
using MongoDB.Bson;
using MongoDB.Bson.IO;
using MongoDB.Driver;

// CONFIG
var sqlConn = Environment.GetEnvironmentVariable("SQL_CONN");
var mongoConn = Environment.GetEnvironmentVariable("MONGO_CONN");
var mongoClient = new MongoClient(mongoConn);

// ØVELSE 1: SQL vs NoSQL
Console.WriteLine("\n=== ØVELSE 1: WEBSHOP ===");

// SQL DEL
using (var db = new WebShopContext())
{
    db.Database.EnsureCreated();
    if (!db.Customers.Any())
    {
        for (int i = 1; i <= 10; i++)
        {
            var customer = new SqlCustomer { Name = $"SQL Kunde {i}" };
            customer.Orders.Add(new SqlOrder { ProductName = $"Vare {i}" });
            db.Customers.Add(customer);
        }
        db.SaveChanges();
    }

    Console.WriteLine("\nSQL Resultat:");
    db.Customers.Include(c => c.Orders).ToList()
      .ForEach(c => Console.WriteLine($"{c.Name} -> {c.Orders[0].ProductName}"));
}

// MONGO DEL
var shopDb = mongoClient.GetDatabase("WebShopDb");
var customerCol = shopDb.GetCollection<MongoCustomer>("Customers");

if (customerCol.CountDocuments(new BsonDocument()) == 0)
{
    for (int i = 1; i <= 10; i++)
    {
        var c = new MongoCustomer { Id = Guid.NewGuid(), Name = $"Mongo Kunde {i}" };
        c.Orders.Add(new MongoOrder { ProductName = $"Vare {i}" });
        customerCol.InsertOne(c);
    }
}

Console.WriteLine("\nMongo Resultat:");
customerCol.Find(new BsonDocument()).ToList()
  .ForEach(c => Console.WriteLine($"{c.Name} -> {c.Orders[0].ProductName}"));


// ØVELSE 2: SCHEMA-LESS (STUDENT DB)
Console.WriteLine("\n=== ØVELSE 2: STUDENT DB (NoSQL) ===");

var studentDb = mongoClient.GetDatabase("StudentDB");
var studentCol = studentDb.GetCollection<BsonDocument>("students");
studentDb.DropCollection("students"); // Nulstil databasen hver gang vi kører demoen

var students = new List<BsonDocument> {
    // Elev 1: Kun personlig info
    new BsonDocument {
        {"Name", "Anna"},
        {"Age", 20},
        {"E-mail", "anna@email.dk"}
    }, 

    // Elev 2: Personlig info + 2 fag
    new BsonDocument {
        {"Name", "Peter"},
        {"Age", 22},
        {"E-mail", "peter@email.dk"},
        {"Subject", new BsonArray{"Databaseprogrammering", "Serversideprogrammering"}}
    }, 

    // Elev 3: Personlig info + 2 fag + læreplads (indlejret dokument)
    new BsonDocument {
        {"Name", "Lotte"},
        {"Age", 25},
        {"E-mail", "lotte@email.dk"},
        {"Subject", new BsonArray{"Databaseprogrammering", "Serversideprogrammering"}},
        {"Employed", new BsonDocument {
            {"Company", "KommuneData"},
            {"City", "Copenhagen"}
        }}
    }
};

// Indsæt data
studentCol.InsertMany(students);

// Udskriv query-resultatet (i json format)
studentCol.Find(new BsonDocument()).ToList()
    .ForEach(s => Console.WriteLine(s.ToJson(new JsonWriterSettings { Indent = true })));