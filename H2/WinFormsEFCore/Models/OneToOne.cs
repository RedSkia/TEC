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
    public uint Id { get; set; } // Primary Key

    // Navigation properties
    public ObjectA A { get; set; } = null!; // Navigation reference to ObjectA
    public ObjectB B { get; set; } = null!; // Navigation reference to ObjectB

    // ObjectA entity
    public class ObjectA : BaseObject
    {
        [Required] // Enforce NOT NULL
        [InverseProperty(nameof(ObjectB.ARef))]
        public ObjectB BRef
        {
            get => field ?? throw new NullReferenceException($"{nameof(BRef)} is required but was not set.");
            set => field = value ?? throw new ArgumentNullException(nameof(BRef));
        } = null!; // Navigation reference to ObjectB
    }

    // ObjectB entity
    [Index(nameof(AId), IsUnique = true)] // Enforce 1:1 uniqueness
    public class ObjectB : BaseObject
    {
        [ForeignKey(nameof(ARef))]
        public uint AId { get; set; } // FK to ObjectA

        [Required] // Enforce NOT NULL
        [InverseProperty(nameof(ObjectA.BRef))]
        public ObjectA ARef
        {
            get => field ?? throw new NullReferenceException($"{nameof(ARef)} is required but was not set.");
            set => field = value ?? throw new ArgumentNullException(nameof(ARef));
        } = null!; // Navigation reference to ObjectA
    }
}