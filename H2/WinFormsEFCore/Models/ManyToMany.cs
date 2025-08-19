using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace WinFormsEFCore.Models;
/* Structure of M:M        
    A: PK
    B: PK
    A_B: FK to A + FK to B
 */

// ManyToMany entity connecting ObjectA and ObjectB
public class ManyToMany : IEntity
{
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)] // Ensure Auto_Increment
    public uint Id { get; set; } // Automatically marked as KEY by EF

    // Navigation properties
    public ObjectA A { get; set; } = null!; // Navigation reference to ObjectA
    public ObjectB B { get; set; } = null!; // Navigation reference to ObjectB

    // ObjectA entity
    public class ObjectA : BaseObject
    {
        public List<ObjectB> BCollection { get; set; } = new(); // Navigation collection to ObjectB
    }

    // ObjectB entity
    public class ObjectB : BaseObject
    {
        public List<ObjectA> ACollection { get; set; } = new(); // Navigation collection to ObjectA
    }

    // Junction table entity connecting ObjectA and ObjectB
    public class ObjectA_B
    {
        [ForeignKey(nameof(ObjectA))]
        public uint AId { get; set; } // Foreign Key reference to ObjectA
        public ObjectA ARef { get; set; } = null!; // Navigation reference to ObjectA

        [ForeignKey(nameof(ObjectB))]
        public uint BId { get; set; } // Foreign Key reference to ObjectB
        public ObjectB BRef { get; set; } = null!; // Navigation reference to ObjectB
    }
}

// Repository for ManyToMany
public class ManyToManyRepository(AppDBContext context) : BaseRepository<ManyToMany>(context);