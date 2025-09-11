using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Windows.Forms;
using WinFormsEFCore.Models;

namespace WinFormsEFCore
{
    public partial class MainForm : Form
    {
        private readonly static AppDBContext _context = new();
        private static DataTable _cachedDataTable = new();



        private RelationshipType _currentMode;
        private enum RelationshipType
        {
            OneToOne,
            OneToMany,
            ManyToMany
        }

        public MainForm()
        {
            InitializeComponent();
        }

        private void Main_Load(object sender, EventArgs e)
        {
            SetupDataGridView();
            PopulateData();
            void SetupDataGridView()
            {
                dataGridView_Database.RowHeadersVisible = false;
                dataGridView_Database.AllowUserToResizeColumns = false;
                dataGridView_Database.AllowUserToResizeRows = false;
                dataGridView_Database.AllowUserToOrderColumns = false;
                dataGridView_Database.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
                dataGridView_Database.MultiSelect = false;
                dataGridView_Database.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.AllCells;
                dataGridView_Database.ReadOnly = false;
            }
            void PopulateData()
            {
                Helper.Generate(100, [
                    () => new OneToOne.ObjectA { Value = Helper.RandomWord() },
                    () => new OneToOne.ObjectB { Value = Helper.RandomWord() }],
                    [ objs => {
                        _ = objs[0] is OneToOne.ObjectA a ? a : a = new();
                        _ = objs[1] is OneToOne.ObjectB b ? b : b = new();
                        a.BRef = b;
                        b.ARef = a;
                    }],
                    objs =>
                    {
                        _ = objs[0] is OneToOne.ObjectA a ? a : a = new();
                        _ = objs[1] is OneToOne.ObjectB b ? b : b = new();
                        _context.OneToOne.Add(new() { A = a, B = b });
                    }
                );
                Helper.Generate(100, [
                    () => new OneToMany.ObjectA { Value = Helper.RandomWord() },
                    () => new OneToMany.ObjectB { Value = Helper.RandomWord() },
                    () => new OneToMany.ObjectB { Value = Helper.RandomWord() },
                    () => new OneToMany.ObjectB { Value = Helper.RandomWord() }],
                    [ objs => {
                        _ = objs[0] is OneToMany.ObjectA a ? a : a = new();
                        _ = objs[1] is OneToMany.ObjectB b1 ? b1 : b1 = new();
                        _ = objs[2] is OneToMany.ObjectB b2 ? b2 : b2 = new();
                        _ = objs[3] is OneToMany.ObjectB b3 ? b3 : b3 = new();
                        a.BCollection.AddRange(b1, b2, b3);
                        b1.ARef = a;
                        b2.ARef = a;
                        b3.ARef = a;
                    }],
                    objs =>
                    {
                        _ = objs[0] is OneToMany.ObjectA a ? a : a = new();
                        _context.OneToMany.Add(new() { A = a });
                    }
                );
                Helper.Generate(100, [
                    () => new ManyToMany.ObjectA { Value = Helper.RandomWord() },
                    () => new ManyToMany.ObjectA { Value = Helper.RandomWord() },
                    () => new ManyToMany.ObjectB { Value = Helper.RandomWord() },
                    () => new ManyToMany.ObjectB { Value = Helper.RandomWord() }],
                    [ objs => {
                        _ = objs[0] is ManyToMany.ObjectA a1 ? a1 : a1 = new();
                        _ = objs[1] is ManyToMany.ObjectA a2 ? a2 : a2 = new();
                        _ = objs[2] is ManyToMany.ObjectB b1 ? b1 : b1 = new();
                        _ = objs[3] is ManyToMany.ObjectB b2 ? b2 : b2 = new();

                        // Create junctions for all unique pairs
                        var linkA1B1 = new ManyToMany.ObjectA_B { ARef = a1, BRef = b1 };
                        var linkA1B2 = new ManyToMany.ObjectA_B { ARef = a1, BRef = b2 };
                        var linkA2B1 = new ManyToMany.ObjectA_B { ARef = a2, BRef = b1 };
                        var linkA2B2 = new ManyToMany.ObjectA_B { ARef = a2, BRef = b2 };

                        // Assign junctions to navigation properties
                        a1.A_BLinks.AddRange(linkA1B1, linkA1B2);
                        a2.A_BLinks.AddRange(linkA2B1, linkA2B2);
                        b1.A_BLinks.AddRange(linkA1B1, linkA2B1);
                        b2.A_BLinks.AddRange(linkA1B2, linkA2B2);
                    }],
                    // Step 2: add entities and junctions to EF context
                    objs =>
                    {
                        _ = objs[0] is ManyToMany.ObjectA a1 ? a1 : a1 = new();
                        _ = objs[1] is ManyToMany.ObjectA a2 ? a2 : a2 = new();
                        _ = objs[2] is ManyToMany.ObjectB b1 ? b1 : b1 = new();
                        _ = objs[3] is ManyToMany.ObjectB b2 ? b2 : b2 = new();

                        // Add all junctions so EF tracks full collections
                        _context.ManyToMany.AddRange(
                        [
                            new() { A = a1, B = b1 },
                        new() { A = a1, B = b2 },
                        new() { A = a2, B = b1 },
                        new() { A = a2, B = b2 }
                        ]);
                    }
                );
                _context.SaveChanges();
            }
        }




        private void radioButton_OneToOne_CheckedChanged(object sender, EventArgs e)
        {
            if (!radioButton_OneToOne.Checked) return;
            _currentMode = RelationshipType.OneToOne;

            _cachedDataTable.Clear();
            _cachedDataTable.Columns.Clear();
            _cachedDataTable.Rows.Clear();
            _cachedDataTable.Columns.Add("Id", typeof(int));
            _cachedDataTable.Columns.Add("A", typeof(string));
            _cachedDataTable.Columns.Add("B", typeof(string));

            foreach (var x in _context.OneToOne
                .Include(e => e.A)
                .Include(e => e.B)
                .AsNoTracking())
            {
                _cachedDataTable.Rows.Add(
                    x.Id, 
                    x.A?.Value, 
                    x.B?.Value
                );
            }

            dataGridView_Database.DataSource = _cachedDataTable;
        }

        private void radioButton_OneToMany_CheckedChanged(object sender, EventArgs e)
        {
            if (!radioButton_OneToMany.Checked) return;
            _currentMode = RelationshipType.OneToMany;

            _cachedDataTable.Clear();
            _cachedDataTable.Columns.Clear();
            _cachedDataTable.Rows.Clear();
            _cachedDataTable.Columns.Add("Id", typeof(int));
            _cachedDataTable.Columns.Add("A", typeof(string));
            _cachedDataTable.Columns.Add("BCollection", typeof(string));

            foreach (var x in _context.OneToMany
                .Include(o => o.A)
                .ThenInclude(a => a.BCollection)
                .AsNoTracking())
            {
                _cachedDataTable.Rows.Add(
                    x?.Id,
                    x?.A?.Value,
                    String.Join(", ", x?.A?.BCollection.Select(b => b.Value) ?? [])
                );
            }

            dataGridView_Database.DataSource = _cachedDataTable;

        }

        private void radioButton_ManyToMany_CheckedChanged(object sender, EventArgs e)
        {
            if (!radioButton_ManyToMany.Checked) return;
            _currentMode = RelationshipType.ManyToMany;

            _cachedDataTable.Clear();
            _cachedDataTable.Columns.Clear();
            _cachedDataTable.Rows.Clear();
            _cachedDataTable.Columns.Add("JunctionId", typeof(int));
            _cachedDataTable.Columns.Add("A_Id", typeof(int));
            _cachedDataTable.Columns.Add("A_Value", typeof(string));
            _cachedDataTable.Columns.Add("A_LinkedB", typeof(string));
            _cachedDataTable.Columns.Add("B_Id", typeof(int));
            _cachedDataTable.Columns.Add("B_Value", typeof(string));
            _cachedDataTable.Columns.Add("B_LinkedA", typeof(string));

            foreach (var m in _context.ManyToMany
                .Include(j => j.A).ThenInclude(a => a.A_BLinks).ThenInclude(link => link.BRef)
                .Include(j => j.B).ThenInclude(b => b.A_BLinks).ThenInclude(link => link.ARef)
                .AsNoTracking())
            {
                _cachedDataTable.Rows.Add(
                    m.Id,
                    m.A?.Id,
                    m.A?.Value,
                    String.Join(", ", m.A?.A_BLinks.Select(link => link.BRef.Value) ?? Enumerable.Empty<string>()),
                    m.B?.Id,
                    m.B?.Value,
                    String.Join(", ", m.B?.A_BLinks.Select(link => link.ARef.Value) ?? Enumerable.Empty<string>())
                );
            }

            dataGridView_Database.DataSource = _cachedDataTable;
        }

        private void button_Update_Click(object sender, EventArgs e)
        {
            try
            {
                switch (_currentMode)
                {
                    case RelationshipType.OneToOne: UpdateOneToOne(); break;
                    case RelationshipType.OneToMany: UpdateOneToMany(); break;
                    case RelationshipType.ManyToMany: UpdateManyToMany(); break;
                    default: throw new ArgumentOutOfRangeException();
                }

                _context.SaveChanges();

                switch (_currentMode)
                {
                    case RelationshipType.OneToOne: radioButton_OneToOne_CheckedChanged(this, EventArgs.Empty); break;
                    case RelationshipType.OneToMany: radioButton_OneToMany_CheckedChanged(this, EventArgs.Empty); break;
                    case RelationshipType.ManyToMany: radioButton_ManyToMany_CheckedChanged(this, EventArgs.Empty); break;
                    default: throw new ArgumentOutOfRangeException();
                }

                MessageBox.Show("Database updated successfully!");
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error updating database: " + ex.Message);
            }
        }

        private void button_Search_Click(object sender, EventArgs e)
        {
            string searchTerm = textBox_Input.Text.Trim().ToLower();

            if (String.IsNullOrEmpty(searchTerm))
            {
                dataGridView_Database.DataSource = _cachedDataTable;
                return;
            }

            var filteredRows = _cachedDataTable.AsEnumerable()
                .Where(row => row.ItemArray.Any(field => field?.ToString()?.Contains(searchTerm, StringComparison.CurrentCultureIgnoreCase) == true));

            dataGridView_Database.DataSource = filteredRows.Any() ? filteredRows.CopyToDataTable() : _cachedDataTable.Clone();
        }

        private void button_Add_Click(object sender, EventArgs e)
        {

        }

        private void button_Delete_Click(object sender, EventArgs e)
        {

        }


        // --- One-to-One ---
        public void UpdateOneToOne()
        {
            foreach (var row in _cachedDataTable.AsEnumerable())
            {
                var entity = _context.Set<OneToOne>()
                    .Include(x => x.A)
                    .Include(x => x.B)
                    .FirstOrDefault(x => x.Id == row.Field<int>("Id"));

                if (entity == null) continue;

                // Update scalar values
                entity.A.Value = row.Field<string>("A");
                entity.B.Value = row.Field<string>("B");

                // EF automatically tracks changes
            }

            _context.SaveChanges();
        }

        // --- One-to-Many ---
        public void UpdateOneToMany()
        {
            foreach (var row in _cachedDataTable.AsEnumerable())
            {
                var entity = _context.Set<OneToMany>()
                    .Include(x => x.A)
                        .ThenInclude(a => a.BCollection)
                    .FirstOrDefault(x => x.Id == row.Field<int>("Id"));

                if (entity == null) continue;

                // Update A value
                entity.A.Value = row.Field<string>("A");

                // Desired B values from input
                var newValues = (row.Field<string>("BCollection") ?? "")
                    .Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries)
                    .ToHashSet();

                // Remove Bs that no longer exist
                foreach (var b in entity.A.BCollection.ToList())
                {
                    if (!newValues.Contains(b.Value))
                        _context.Remove(b);
                    else
                        newValues.Remove(b.Value); // Already exists
                }

                // Add any new Bs
                foreach (var val in newValues)
                {
                    entity.A.BCollection.Add(new OneToMany.ObjectB
                    {
                        Value = val,
                        ARef = entity.A
                    });
                }
            }

            _context.SaveChanges();
        }

        // --- Many-to-Many ---
        public void UpdateManyToMany()
        {
            // Load all B objects into memory to avoid repeated DB queries
            var allBs = _context.Set<ManyToMany.ObjectB>().ToList();

            foreach (var row in _cachedDataTable.AsEnumerable())
            {
                int junctionId = row.Field<int>("JunctionId");

                var entity = _context.Set<ManyToMany>()
                    .Include(m => m.A).ThenInclude(a => a.A_BLinks).ThenInclude(link => link.BRef)
                    .Include(m => m.B).ThenInclude(b => b.A_BLinks).ThenInclude(link => link.ARef)
                    .FirstOrDefault(m => m.Id == junctionId);

                if (entity == null) continue;

                string newAValue = row.Field<string>("A_Value")?.Trim() ?? string.Empty;
                string newBValue = row.Field<string>("B_Value")?.Trim() ?? string.Empty;

                // --- Update A and propagate ---
                if (entity.A.Value != newAValue)
                {
                    entity.A.Value = newAValue;
                    _context.Entry(entity.A).State = EntityState.Modified;

                    // Propagate A value to all references
                    foreach (var link in entity.A.A_BLinks)
                    {
                        if (link.BRef != null)
                            _context.Entry(link.BRef).State = EntityState.Modified;
                    }
                }

                // --- Update B and propagate ---
                if (entity.B.Value != newBValue)
                {
                    entity.B.Value = newBValue;
                    _context.Entry(entity.B).State = EntityState.Modified;

                    // Propagate B value to all references
                    foreach (var link in entity.B.A_BLinks)
                    {
                        if (link.ARef != null)
                            _context.Entry(link.ARef).State = EntityState.Modified;
                    }
                }

                // --- Update A -> B links ---
                var newBValues = (row.Field<string>("A_LinkedB") ?? "")
                    .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                    .ToHashSet(StringComparer.Ordinal);

                var existingLinks = entity.A.A_BLinks.ToList();

                // Remove old links
                foreach (var link in existingLinks)
                {
                    if (!newBValues.Contains(link.BRef.Value))
                    {
                        entity.A.A_BLinks.Remove(link);
                        _context.Remove(link);
                    }
                    else
                    {
                        newBValues.Remove(link.BRef.Value); // Already exists
                    }
                }

                // Add new links safely
                foreach (var bVal in newBValues)
                {
                    // Reuse existing tracked entity if exists
                    var b = allBs.FirstOrDefault(x => x.Value == bVal);
                    if (b == null)
                    {
                        b = new ManyToMany.ObjectB { Value = bVal };
                        _context.Add(b);
                        allBs.Add(b);
                    }

                    // Avoid duplicate links
                    if (!entity.A.A_BLinks.Any(l => l.BRef.Value == bVal))
                    {
                        var newLink = new ManyToMany.ObjectA_B { ARef = entity.A, BRef = b };
                        entity.A.A_BLinks.Add(newLink);
                    }
                }

                // Ensure bidirectional consistency
                foreach (var link in entity.A.A_BLinks)
                {
                    if (!link.BRef.A_BLinks.Contains(link))
                        link.BRef.A_BLinks.Add(link);
                }
            }

            // Detect and save only actual changes
            foreach (var entry in _context.ChangeTracker.Entries())
            {
                if (entry.State == EntityState.Modified)
                {
                    // EF will only update properties that actually changed
                }
            }

            _context.SaveChanges();
        }















    }
}
