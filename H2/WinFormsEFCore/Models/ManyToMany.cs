using System.Collections.Generic;
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
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public uint Id { get; set; }

    public ObjectA A { get; set; } = null!;
    public ObjectB B { get; set; } = null!;

    // ObjectA entity
    public class ObjectA : BaseObject
    {
        public List<ObjectA_B> A_BLinks { get; set; } = new();
    }

    // ObjectB entity
    public class ObjectB : BaseObject
    {
        public List<ObjectA_B> A_BLinks { get; set; } = new();
    }

    // Junction table connecting ObjectA and ObjectB
    public class ObjectA_B
    {
        public uint AId { get; set; } // FK to ObjectA
        [ForeignKey(nameof(AId))]
        public ObjectA ARef { get; set; } = null!;

        public uint BId { get; set; } // FK to ObjectB
        [ForeignKey(nameof(BId))]
        public ObjectB BRef { get; set; } = null!;
    }
}

