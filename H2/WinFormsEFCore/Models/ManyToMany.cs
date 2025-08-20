using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WinFormsEFCore.Models;
/* Structure of M:M        
    A: PK
    B: PK
    A_B: FK to A + FK to B
 */

// ManyToMany entity connecting ObjectA and ObjectB
public class ManyToMany
{
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)] // Ensure Auto_Increment
    public uint Id { get; set; } // Primary Key for this link row

    // Navigation properties
    public ObjectA A { get; set; } = null!; // Navigation reference to ObjectA
    public ObjectB B { get; set; } = null!; // Navigation reference to ObjectB

    // ObjectA entity
    public class ObjectA : BaseObject
    {
        [InverseProperty(nameof(ObjectA_B.ARef))]
        public List<ObjectA_B> A_BLinks { get; set; } = new(); // Links to B via junction
    }

    // ObjectB entity
    public class ObjectB : BaseObject
    {
        [InverseProperty(nameof(ObjectA_B.BRef))]
        public List<ObjectA_B> A_BLinks { get; set; } = new(); // Links to A via junction
    }

    // Junction entity connecting ObjectA and ObjectB
    [PrimaryKey(nameof(AId), nameof(BId))] // Composite PK (AId + BId)
    public class ObjectA_B
    {
        [Required]
        public uint AId { get; set; } // FK to ObjectA

        [ForeignKey(nameof(AId))]
        public ObjectA ARef { get; set; } = null!; // Navigation reference to ObjectA

        [Required]
        public uint BId { get; set; } // FK to ObjectB

        [ForeignKey(nameof(BId))]
        public ObjectB BRef { get; set; } = null!; // Navigation reference to ObjectB
    }
}