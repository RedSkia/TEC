namespace BankApp
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
            label_AccountId = new Label();
            label_AccountAmount = new Label();
            numericUpDown_AccountAmount = new NumericUpDown();
            dataGridView_Accounts = new DataGridView();
            button_CreateAccount = new Button();
            button_Deposit = new Button();
            button_Withdraw = new Button();
            tableLayoutPanel1 = new TableLayoutPanel();
            button_DeleteAccount = new Button();
            comboBox_AccountSelector = new ComboBox();
            ((System.ComponentModel.ISupportInitialize)numericUpDown_AccountAmount).BeginInit();
            ((System.ComponentModel.ISupportInitialize)dataGridView_Accounts).BeginInit();
            tableLayoutPanel1.SuspendLayout();
            SuspendLayout();
            // 
            // label_AccountId
            // 
            label_AccountId.Anchor = AnchorStyles.Left | AnchorStyles.Right;
            label_AccountId.AutoSize = true;
            label_AccountId.Location = new Point(3, 8);
            label_AccountId.Name = "label_AccountId";
            label_AccountId.Size = new Size(140, 32);
            label_AccountId.TabIndex = 0;
            label_AccountId.Text = "AccountId";
            // 
            // label_AccountAmount
            // 
            label_AccountAmount.Anchor = AnchorStyles.Left | AnchorStyles.Right;
            label_AccountAmount.AutoSize = true;
            label_AccountAmount.Location = new Point(3, 56);
            label_AccountAmount.Name = "label_AccountAmount";
            label_AccountAmount.Size = new Size(140, 32);
            label_AccountAmount.TabIndex = 1;
            label_AccountAmount.Text = "Amount";
            // 
            // numericUpDown_AccountAmount
            // 
            numericUpDown_AccountAmount.Dock = DockStyle.Fill;
            numericUpDown_AccountAmount.Location = new Point(149, 51);
            numericUpDown_AccountAmount.Maximum = new decimal(new int[] { 9999999, 0, 0, 0 });
            numericUpDown_AccountAmount.Name = "numericUpDown_AccountAmount";
            numericUpDown_AccountAmount.Size = new Size(376, 39);
            numericUpDown_AccountAmount.TabIndex = 3;
            // 
            // dataGridView_Accounts
            // 
            dataGridView_Accounts.AllowUserToAddRows = false;
            dataGridView_Accounts.AllowUserToDeleteRows = false;
            dataGridView_Accounts.Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right;
            dataGridView_Accounts.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
            dataGridView_Accounts.ColumnHeadersHeightSizeMode = DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            dataGridView_Accounts.Location = new Point(6, 108);
            dataGridView_Accounts.MultiSelect = false;
            dataGridView_Accounts.Name = "dataGridView_Accounts";
            dataGridView_Accounts.ReadOnly = true;
            dataGridView_Accounts.RowHeadersWidth = 51;
            dataGridView_Accounts.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
            dataGridView_Accounts.Size = new Size(970, 440);
            dataGridView_Accounts.TabIndex = 4;
            dataGridView_Accounts.KeyDown += dataGridView_Accounts_KeyDown;
            // 
            // button_CreateAccount
            // 
            button_CreateAccount.AutoSize = true;
            button_CreateAccount.Dock = DockStyle.Fill;
            button_CreateAccount.Location = new Point(531, 3);
            button_CreateAccount.Name = "button_CreateAccount";
            button_CreateAccount.Size = new Size(214, 42);
            button_CreateAccount.TabIndex = 5;
            button_CreateAccount.Text = "Create Account";
            button_CreateAccount.UseVisualStyleBackColor = true;
            button_CreateAccount.Click += button_CreateAccount_Click;
            // 
            // button_Deposit
            // 
            button_Deposit.AutoSize = true;
            button_Deposit.Dock = DockStyle.Fill;
            button_Deposit.Location = new Point(531, 51);
            button_Deposit.Name = "button_Deposit";
            button_Deposit.Size = new Size(214, 42);
            button_Deposit.TabIndex = 6;
            button_Deposit.Text = "Deposit";
            button_Deposit.UseVisualStyleBackColor = true;
            button_Deposit.Click += button_Deposit_Click;
            // 
            // button_Withdraw
            // 
            button_Withdraw.AutoSize = true;
            button_Withdraw.Dock = DockStyle.Fill;
            button_Withdraw.Location = new Point(751, 51);
            button_Withdraw.Name = "button_Withdraw";
            button_Withdraw.Size = new Size(214, 42);
            button_Withdraw.TabIndex = 7;
            button_Withdraw.Text = "Withdraw";
            button_Withdraw.UseVisualStyleBackColor = true;
            button_Withdraw.Click += button_Withdraw_Click;
            // 
            // tableLayoutPanel1
            // 
            tableLayoutPanel1.Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right;
            tableLayoutPanel1.AutoSize = true;
            tableLayoutPanel1.ColumnCount = 4;
            tableLayoutPanel1.ColumnStyles.Add(new ColumnStyle());
            tableLayoutPanel1.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
            tableLayoutPanel1.ColumnStyles.Add(new ColumnStyle());
            tableLayoutPanel1.ColumnStyles.Add(new ColumnStyle());
            tableLayoutPanel1.Controls.Add(button_DeleteAccount, 3, 0);
            tableLayoutPanel1.Controls.Add(label_AccountId, 0, 0);
            tableLayoutPanel1.Controls.Add(button_Withdraw, 3, 1);
            tableLayoutPanel1.Controls.Add(label_AccountAmount, 0, 1);
            tableLayoutPanel1.Controls.Add(button_Deposit, 2, 1);
            tableLayoutPanel1.Controls.Add(button_CreateAccount, 2, 0);
            tableLayoutPanel1.Controls.Add(numericUpDown_AccountAmount, 1, 1);
            tableLayoutPanel1.Controls.Add(comboBox_AccountSelector, 1, 0);
            tableLayoutPanel1.Location = new Point(7, 6);
            tableLayoutPanel1.Name = "tableLayoutPanel1";
            tableLayoutPanel1.RowCount = 2;
            tableLayoutPanel1.RowStyles.Add(new RowStyle());
            tableLayoutPanel1.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
            tableLayoutPanel1.Size = new Size(968, 96);
            tableLayoutPanel1.TabIndex = 8;
            // 
            // button_DeleteAccount
            // 
            button_DeleteAccount.AutoSize = true;
            button_DeleteAccount.Dock = DockStyle.Fill;
            button_DeleteAccount.Location = new Point(751, 3);
            button_DeleteAccount.Name = "button_DeleteAccount";
            button_DeleteAccount.Size = new Size(214, 42);
            button_DeleteAccount.TabIndex = 9;
            button_DeleteAccount.Text = "Delete Account";
            button_DeleteAccount.UseVisualStyleBackColor = true;
            button_DeleteAccount.Click += button_DeleteAccount_Click;
            // 
            // comboBox_AccountSelector
            // 
            comboBox_AccountSelector.Dock = DockStyle.Fill;
            comboBox_AccountSelector.FormattingEnabled = true;
            comboBox_AccountSelector.Location = new Point(149, 3);
            comboBox_AccountSelector.Name = "comboBox_AccountSelector";
            comboBox_AccountSelector.Size = new Size(376, 40);
            comboBox_AccountSelector.TabIndex = 8;
            // 
            // MainForm
            // 
            AutoScaleDimensions = new SizeF(16F, 32F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(982, 553);
            Controls.Add(tableLayoutPanel1);
            Controls.Add(dataGridView_Accounts);
            Font = new Font("Arial", 16.2F, FontStyle.Regular, GraphicsUnit.Point, 0);
            Margin = new Padding(6, 4, 6, 4);
            MinimumSize = new Size(600, 300);
            Name = "MainForm";
            Text = "BankApp";
            Load += MainForm_Load;
            ((System.ComponentModel.ISupportInitialize)numericUpDown_AccountAmount).EndInit();
            ((System.ComponentModel.ISupportInitialize)dataGridView_Accounts).EndInit();
            tableLayoutPanel1.ResumeLayout(false);
            tableLayoutPanel1.PerformLayout();
            ResumeLayout(false);
            PerformLayout();
        }

        #endregion

        private Label label_AccountId;
        private Label label_AccountAmount;
        private NumericUpDown numericUpDown_AccountAmount;
        private DataGridView dataGridView_Accounts;
        private Button button_CreateAccount;
        private Button button_Deposit;
        private Button button_Withdraw;
        private TableLayoutPanel tableLayoutPanel1;
        private ComboBox comboBox_AccountSelector;
        private Button button_DeleteAccount;
    }
}
