using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace WinFormsEFCore.Models;
/* Structure of 1:M        
    A: PK
    B: PK + FK to A
 */

// OneToMany entity connecting ObjectA and ObjectB
public class OneToMany : IEntity
{
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)] // Ensure Auto_Increment
    public uint Id { get; set; } // Automatically marked as KEY by EF

    // Navigation properties
    public ObjectA A { get; set; } = null!; // Navigation reference to ObjectA
    public ObjectB B { get; set; } = null!; // Navigation reference to ObjectB

    // ObjectA entity
    public class ObjectA : BaseObject
    {
        public ICollection<ObjectB> BCollection { get; set; } = new List<ObjectB>(); // Navigation collection to ObjectB
    }

    // ObjectB entity
    public class ObjectB : BaseObject
    {
        [ForeignKey(nameof(ObjectA))]
        public uint AId { get; set; } // Foreign Key reference
        public ObjectA ARef { get; set; } = null!; // Navigation reference to ObjectA
    }
}

// Repository for OneToMany
public class OneToManyRepository(AppDBContext context) : BaseRepository<OneToMany>(context);