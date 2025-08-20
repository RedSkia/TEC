using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Windows.Forms;
using WinFormsEFCore.Models;

namespace WinFormsEFCore
{
    public partial class MainForm : Form
    {
        private readonly static AppDBContext _context = new();

        private static List<object> _cachedData = new();

        public MainForm()
        {
            InitializeComponent();
        }

        private void Main_Load(object sender, EventArgs e)
        {
            dataGridView_Database.RowHeadersVisible = false;
            dataGridView_Database.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.AllCells;

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





        private void radioButton_OneToOne_CheckedChanged(object sender, EventArgs e)
        {
            _cachedData = _context.OneToOne.AsNoTracking().Select(x => new
            {
                Id = x.Id,
                A = x.A.Value,
                B = x.B.Value,
            }).Cast<object>().ToList();
            dataGridView_Database.DataSource = _cachedData;
        }

        private void radioButton_OneToMany_CheckedChanged(object sender, EventArgs e)
        {
            _cachedData = _context.OneToMany.AsNoTracking().Select(x => new
            {
                Id = x.Id,
                A = x.A.Value,
                BCollection = string.Join(", ", x.A.BCollection.Select(b => b.Value))
            }).Cast<object>().ToList();
            dataGridView_Database.DataSource = _cachedData;
        }

        private void radioButton_ManyToMany_CheckedChanged(object sender, EventArgs e)
        {
            _cachedData = _context.ManyToMany
                .AsNoTracking()
                .Select(m => new
                {
                    JunctionId = m.Id,

                    // Info about A
                    A_Id = m.A.Id,
                    A_Value = m.A.Value,
                    A_LinkedB_Ids = string.Join(", ", m.A.A_BLinks.Select(link => link.BRef.Id)),
                    A_LinkedB_Values = string.Join(", ", m.A.A_BLinks.Select(link => link.BRef.Value)),

                    // Info about B
                    B_Id = m.B.Id,
                    B_Value = m.B.Value,
                    B_LinkedA_Ids = string.Join(", ", m.B.A_BLinks.Select(link => link.ARef.Id)),
                    B_LinkedA_Values = string.Join(", ", m.B.A_BLinks.Select(link => link.ARef.Value))
                })
                .Cast<object>().ToList();
            dataGridView_Database.DataSource = _cachedData;
        }

        private void button_Update_Click(object sender, EventArgs e)
        {

        }

        private void button_Search_Click(object sender, EventArgs e)
        {
            string searchTerm = textBox_Input.Text.Trim().ToLower();

            if (string.IsNullOrEmpty(searchTerm))
            {
                dataGridView_Database.DataSource = _cachedData;
                return;
            }

            var filtered = _cachedData
                .Where(item => item.GetType().GetProperties()
                    .Any(prop => (prop.GetValue(item)?.ToString() ?? "").ToLower().Contains(searchTerm)))
                .ToList();

            dataGridView_Database.DataSource = filtered;
        }

        private void button_Add_Click(object sender, EventArgs e)
        {

        }

        private void button_Delete_Click(object sender, EventArgs e)
        {

        }
    }
}
