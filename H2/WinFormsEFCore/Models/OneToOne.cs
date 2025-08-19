using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations.Schema;
using System;
using System.ComponentModel.DataAnnotations;

namespace WinFormsEFCore.Models;
/* Structure of 1:1
    A: PK
    B: PK + FK to A (unique)
 */

// OneToOne entity connecting ObjectA and ObjectB
public class OneToOne
{
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)] // Ensure Auto_Increment
    public uint Id { get; set; } // Automatically marked as KEY by EF

    // Navigation properties
    public ObjectA A { get; set; } = null!; // Navigation reference to ObjectA
    public ObjectB B { get; set; } = null!; // Navigation reference to ObjectB

    // ObjectA entity
    public class ObjectA : BaseObject
    {
        [Required] // Enforce NOT NULL in DB
        [InverseProperty(nameof(ObjectB.ARef))]
        public ObjectB BRef
        {
            get => field ?? throw new NullReferenceException($"{nameof(BRef)} is required but was not set.");
            set => field = value ?? throw new ArgumentNullException(nameof(BRef));
        } = null!; // Navigation reference to ObjectB
    }

    // ObjectB entity
    [Index(nameof(AId), IsUnique = true)] // Ensure Unique to make relation 1:1
    public class ObjectB : BaseObject
    {
        [ForeignKey(nameof(ARef))]
        public uint AId { get; set; } // Foreign Key reference

        [Required] // Enforce NOT NULL in DB
        [InverseProperty(nameof(ObjectA.BRef))]
        public ObjectA ARef
        {
            get => field ?? throw new NullReferenceException($"{nameof(ARef)} is required but was not set.");
            set => field = value ?? throw new ArgumentNullException(nameof(ARef));
        } = null!; // Navigation reference to ObjectA
    }
}

    //public override void CreateData(ushort count = 100)
    //{
    //    var random = new Random();

    //    for (int i = 0; i < count; i++)
    //    {
    //        // Create ObjectA with random value
    //        OneToOne.ObjectA objectA = new()
    //        {
    //            Value = Helper.RandomWord()
    //        };

    //        // Create ObjectB with random value
    //        OneToOne.ObjectB objectB = new()
    //        {
    //            Value = Helper.RandomWord()
    //        };

    //        // Link them
    //        objectA.BRef = objectB;
    //        objectB.ARef = objectA;

    //        // Add to repository
    //        Add(new OneToOne()
    //        {
    //            A = objectA,
    //            B = objectB,
    //        });
    //    }
    //}