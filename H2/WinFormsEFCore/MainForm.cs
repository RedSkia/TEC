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
                objs => {
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
                objs => {
                    _ = objs[0] is OneToMany.ObjectA a ? a : a = new();
                    _context.OneToMany.Add(new() { A = a });
                }
            );



            _context.SaveChanges();
        }
    


        

        private void radioButton_OneToOne_CheckedChanged(object sender, EventArgs e)
        {
            dataGridView_Database.DataSource = _context.OneToOne.AsNoTracking().Select(x => new
            {
                Id = x.Id,
                A = x.A.Value,
                B = x.B.Value,
            }).ToList();
        }

        private void radioButton_OneToMany_CheckedChanged(object sender, EventArgs e)
        {
            dataGridView_Database.DataSource = _context.OneToMany.AsNoTracking().Select(x => new
            {
                Id = x.Id,
                A = x.A.Value,
                BCollection = string.Join(", ", x.A.BCollection.Select(b => b.Value))
            }).ToList();
        }

        private void radioButton_ManyToMany_CheckedChanged(object sender, EventArgs e)
        {

        }
    }
}
