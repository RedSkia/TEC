using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WinFormsEFCore.Models;
/* Structure of 1:M        
    A: PK
    B: PK + FK to A
 */

// OneToMany entity connecting ObjectA and ObjectB
public class OneToMany
{
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)] // Ensure Auto_Increment
    public uint Id { get; set; } // Automatically marked as KEY by EF

    // Navigation properties
    public ObjectA A { get; set; } = null!; // Navigation reference to ObjectA
    public ObjectB B { get; set; } = null!; // Navigation reference to ObjectB

    // ObjectA entity
    public class ObjectA : BaseObject
    {
        [InverseProperty(nameof(ObjectB.ARef))]
        public List<ObjectB> BCollection { get; set; } = new(); // Navigation collection to ObjectB
    }

    // ObjectB entity
    public class ObjectB : BaseObject
    {
        [ForeignKey(nameof(ARef))]
        public uint AId { get; set; } // Foreign Key reference

        [Required] // Enforce NOT NULL in DB
        [InverseProperty(nameof(ObjectA.BCollection))]
        public ObjectA ARef
        {
            get => field ?? throw new NullReferenceException($"{nameof(ARef)} is required but was not set.");
            set => field = value ?? throw new ArgumentNullException(nameof(ARef));
        } = null!; // Navigation reference to ObjectA
    }
}