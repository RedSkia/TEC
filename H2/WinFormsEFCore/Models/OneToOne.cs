using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations.Schema;

namespace WinFormsEFCore.Models;
/* Structure of 1:1
    A: PK
    B: PK + FK to A (unique)
 */

// OneToOne entity connecting ObjectA and ObjectB
public class OneToOne : IEntity
{
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)] // Ensure Auto_Increment
    public uint Id { get; set; } // Automatically marked as KEY by EF

    // Navigation properties
    public ObjectA A { get; set; } = null!; // Navigation reference to ObjectA
    public ObjectB B { get; set; } = null!; // Navigation reference to ObjectB

    // ObjectA entity
    public class ObjectA : BaseObject
    {
        public ObjectB? BRef { get; set; } // Navigation reference to ObjectB
    }

    // ObjectB entity
    [Index(nameof(AId), IsUnique = true)] // Ensure Unique to make relation 1:1
    public class ObjectB : BaseObject
    {
        [ForeignKey(nameof(ObjectA))]
        public uint AId { get; set; } // Foreign Key reference
        public ObjectA ARef { get; set; } = null!; // Navigation reference to ObjectA
    }
}

// Repository for OneToOne
public class OneToOneRepository(AppDBContext context) : BaseRepository<OneToOne>(context);