using System.Drawing;
using System.Windows.Forms;

namespace WinFormsEFCore
{
    partial class MainForm
    {
        /// <summary>
        ///  Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        ///  Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        ///  Required method for Designer support - do not modify
        ///  the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            dataGridView_Database = new DataGridView();
            radioButton_OneToOne = new RadioButton();
            radioButton_OneToMany = new RadioButton();
            radioButton_ManyToMany = new RadioButton();
            groupBox_RelationshipSelector = new GroupBox();
            tableLayoutPanel1 = new TableLayoutPanel();
            button_Delete = new Button();
            button_Add = new Button();
            button_Update = new Button();
            textBox_Input = new TextBox();
            tableLayoutPanel2 = new TableLayoutPanel();
            button_Search = new Button();
            ((System.ComponentModel.ISupportInitialize)dataGridView_Database).BeginInit();
            groupBox_RelationshipSelector.SuspendLayout();
            tableLayoutPanel1.SuspendLayout();
            tableLayoutPanel2.SuspendLayout();
            SuspendLayout();
            // 
            // dataGridView_Database
            // 
            dataGridView_Database.Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right;
            dataGridView_Database.ColumnHeadersHeightSizeMode = DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            dataGridView_Database.Location = new Point(8, 72);
            dataGridView_Database.Name = "dataGridView_Database";
            dataGridView_Database.RowHeadersWidth = 51;
            dataGridView_Database.Size = new Size(966, 474);
            dataGridView_Database.TabIndex = 0;
            // 
            // radioButton_OneToOne
            // 
            radioButton_OneToOne.AutoSize = true;
            radioButton_OneToOne.Dock = DockStyle.Fill;
            radioButton_OneToOne.Location = new Point(3, 3);
            radioButton_OneToOne.Name = "radioButton_OneToOne";
            radioButton_OneToOne.Size = new Size(86, 24);
            radioButton_OneToOne.TabIndex = 1;
            radioButton_OneToOne.Text = "1:1";
            radioButton_OneToOne.UseVisualStyleBackColor = true;
            radioButton_OneToOne.CheckedChanged += radioButton_OneToOne_CheckedChanged;
            // 
            // radioButton_OneToMany
            // 
            radioButton_OneToMany.AutoSize = true;
            radioButton_OneToMany.Dock = DockStyle.Fill;
            radioButton_OneToMany.Location = new Point(95, 3);
            radioButton_OneToMany.Name = "radioButton_OneToMany";
            radioButton_OneToMany.Size = new Size(86, 24);
            radioButton_OneToMany.TabIndex = 2;
            radioButton_OneToMany.Text = "1:M";
            radioButton_OneToMany.UseVisualStyleBackColor = true;
            radioButton_OneToMany.CheckedChanged += radioButton_OneToMany_CheckedChanged;
            // 
            // radioButton_ManyToMany
            // 
            radioButton_ManyToMany.AutoSize = true;
            radioButton_ManyToMany.Dock = DockStyle.Fill;
            radioButton_ManyToMany.Location = new Point(187, 3);
            radioButton_ManyToMany.Name = "radioButton_ManyToMany";
            radioButton_ManyToMany.Size = new Size(86, 24);
            radioButton_ManyToMany.TabIndex = 3;
            radioButton_ManyToMany.Text = "M:M";
            radioButton_ManyToMany.UseVisualStyleBackColor = true;
            radioButton_ManyToMany.CheckedChanged += radioButton_ManyToMany_CheckedChanged;
            // 
            // groupBox_RelationshipSelector
            // 
            groupBox_RelationshipSelector.AutoSize = true;
            groupBox_RelationshipSelector.Controls.Add(tableLayoutPanel1);
            groupBox_RelationshipSelector.Font = new Font("Arial", 11F);
            groupBox_RelationshipSelector.Location = new Point(8, 9);
            groupBox_RelationshipSelector.Margin = new Padding(0);
            groupBox_RelationshipSelector.Name = "groupBox_RelationshipSelector";
            groupBox_RelationshipSelector.Padding = new Padding(2);
            groupBox_RelationshipSelector.Size = new Size(280, 56);
            groupBox_RelationshipSelector.TabIndex = 4;
            groupBox_RelationshipSelector.TabStop = false;
            groupBox_RelationshipSelector.Text = "Relationship Selector";
            // 
            // tableLayoutPanel1
            // 
            tableLayoutPanel1.ColumnCount = 3;
            tableLayoutPanel1.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 33.3333321F));
            tableLayoutPanel1.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 33.3333321F));
            tableLayoutPanel1.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 33.3333321F));
            tableLayoutPanel1.Controls.Add(radioButton_ManyToMany, 2, 0);
            tableLayoutPanel1.Controls.Add(radioButton_OneToOne, 0, 0);
            tableLayoutPanel1.Controls.Add(radioButton_OneToMany, 1, 0);
            tableLayoutPanel1.Dock = DockStyle.Fill;
            tableLayoutPanel1.Location = new Point(2, 24);
            tableLayoutPanel1.Margin = new Padding(2);
            tableLayoutPanel1.Name = "tableLayoutPanel1";
            tableLayoutPanel1.RowCount = 1;
            tableLayoutPanel1.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
            tableLayoutPanel1.Size = new Size(276, 30);
            tableLayoutPanel1.TabIndex = 5;
            // 
            // button_Delete
            // 
            button_Delete.Dock = DockStyle.Fill;
            button_Delete.Location = new Point(580, 2);
            button_Delete.Margin = new Padding(2);
            button_Delete.Name = "button_Delete";
            button_Delete.Size = new Size(96, 30);
            button_Delete.TabIndex = 5;
            button_Delete.Text = "Delete";
            button_Delete.UseVisualStyleBackColor = true;
            // 
            // button_Add
            // 
            button_Add.Dock = DockStyle.Fill;
            button_Add.Location = new Point(480, 2);
            button_Add.Margin = new Padding(2);
            button_Add.Name = "button_Add";
            button_Add.Size = new Size(96, 30);
            button_Add.TabIndex = 6;
            button_Add.Text = "Add";
            button_Add.UseVisualStyleBackColor = true;
            // 
            // button_Update
            // 
            button_Update.Dock = DockStyle.Fill;
            button_Update.Location = new Point(280, 2);
            button_Update.Margin = new Padding(2);
            button_Update.Name = "button_Update";
            button_Update.Size = new Size(96, 30);
            button_Update.TabIndex = 7;
            button_Update.Text = "Update";
            button_Update.UseVisualStyleBackColor = true;
            // 
            // textBox_Input
            // 
            textBox_Input.Anchor = AnchorStyles.Left | AnchorStyles.Right;
            textBox_Input.Location = new Point(2, 2);
            textBox_Input.Margin = new Padding(2);
            textBox_Input.Name = "textBox_Input";
            textBox_Input.Size = new Size(274, 30);
            textBox_Input.TabIndex = 8;
            // 
            // tableLayoutPanel2
            // 
            tableLayoutPanel2.Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right;
            tableLayoutPanel2.ColumnCount = 5;
            tableLayoutPanel2.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
            tableLayoutPanel2.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 100F));
            tableLayoutPanel2.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 100F));
            tableLayoutPanel2.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 100F));
            tableLayoutPanel2.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 100F));
            tableLayoutPanel2.Controls.Add(button_Search, 2, 0);
            tableLayoutPanel2.Controls.Add(textBox_Input, 0, 0);
            tableLayoutPanel2.Controls.Add(button_Update, 1, 0);
            tableLayoutPanel2.Controls.Add(button_Delete, 4, 0);
            tableLayoutPanel2.Controls.Add(button_Add, 3, 0);
            tableLayoutPanel2.Font = new Font("Arial", 12F);
            tableLayoutPanel2.Location = new Point(296, 33);
            tableLayoutPanel2.Margin = new Padding(2);
            tableLayoutPanel2.Name = "tableLayoutPanel2";
            tableLayoutPanel2.RowCount = 1;
            tableLayoutPanel2.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
            tableLayoutPanel2.Size = new Size(678, 34);
            tableLayoutPanel2.TabIndex = 9;
            // 
            // button_Search
            // 
            button_Search.Dock = DockStyle.Fill;
            button_Search.Location = new Point(380, 2);
            button_Search.Margin = new Padding(2);
            button_Search.Name = "button_Search";
            button_Search.Size = new Size(96, 30);
            button_Search.TabIndex = 9;
            button_Search.Text = "Search";
            button_Search.UseVisualStyleBackColor = true;
            // 
            // MainForm
            // 
            AutoScaleDimensions = new SizeF(11F, 23F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(982, 553);
            Controls.Add(tableLayoutPanel2);
            Controls.Add(groupBox_RelationshipSelector);
            Controls.Add(dataGridView_Database);
            Font = new Font("Arial", 12F);
            Margin = new Padding(4, 3, 4, 3);
            Name = "MainForm";
            StartPosition = FormStartPosition.CenterScreen;
            Text = "EF Core App";
            Load += Main_Load;
            ((System.ComponentModel.ISupportInitialize)dataGridView_Database).EndInit();
            groupBox_RelationshipSelector.ResumeLayout(false);
            tableLayoutPanel1.ResumeLayout(false);
            tableLayoutPanel1.PerformLayout();
            tableLayoutPanel2.ResumeLayout(false);
            tableLayoutPanel2.PerformLayout();
            ResumeLayout(false);
            PerformLayout();
        }

        #endregion

        private DataGridView dataGridView_Database;
        private RadioButton radioButton_OneToOne;
        private RadioButton radioButton_OneToMany;
        private RadioButton radioButton_ManyToMany;
        private GroupBox groupBox_RelationshipSelector;
        private TableLayoutPanel tableLayoutPanel1;
        private Button button_Delete;
        private Button button_Add;
        private Button button_Update;
        private TextBox textBox_Input;
        private TableLayoutPanel tableLayoutPanel2;
        private Button button_Search;
    }
}
