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
            label_AccountOwner = new Label();
            label_AccountAmount = new Label();
            textBox_AccountOwner = new TextBox();
            numericUpDown_AccountAmount = new NumericUpDown();
            dataGridView_Accounts = new DataGridView();
            button_CreateAccount = new Button();
            button_Deposit = new Button();
            button_Withdraw = new Button();
            tableLayoutPanel1 = new TableLayoutPanel();
            ((System.ComponentModel.ISupportInitialize)numericUpDown_AccountAmount).BeginInit();
            ((System.ComponentModel.ISupportInitialize)dataGridView_Accounts).BeginInit();
            tableLayoutPanel1.SuspendLayout();
            SuspendLayout();
            // 
            // label_AccountOwner
            // 
            label_AccountOwner.Anchor = AnchorStyles.Left | AnchorStyles.Right;
            label_AccountOwner.AutoSize = true;
            label_AccountOwner.Location = new Point(3, 8);
            label_AccountOwner.Name = "label_AccountOwner";
            label_AccountOwner.Size = new Size(88, 32);
            label_AccountOwner.TabIndex = 0;
            label_AccountOwner.Text = "label1";
            // 
            // label_AccountAmount
            // 
            label_AccountAmount.Anchor = AnchorStyles.Left | AnchorStyles.Right;
            label_AccountAmount.AutoSize = true;
            label_AccountAmount.Location = new Point(3, 56);
            label_AccountAmount.Name = "label_AccountAmount";
            label_AccountAmount.Size = new Size(88, 32);
            label_AccountAmount.TabIndex = 1;
            label_AccountAmount.Text = "label1";
            // 
            // textBox_AccountOwner
            // 
            textBox_AccountOwner.Dock = DockStyle.Fill;
            textBox_AccountOwner.Location = new Point(97, 3);
            textBox_AccountOwner.Name = "textBox_AccountOwner";
            textBox_AccountOwner.Size = new Size(501, 39);
            textBox_AccountOwner.TabIndex = 2;
            // 
            // numericUpDown_AccountAmount
            // 
            numericUpDown_AccountAmount.Dock = DockStyle.Fill;
            numericUpDown_AccountAmount.Location = new Point(97, 51);
            numericUpDown_AccountAmount.Name = "numericUpDown_AccountAmount";
            numericUpDown_AccountAmount.Size = new Size(501, 39);
            numericUpDown_AccountAmount.TabIndex = 3;
            // 
            // dataGridView_Accounts
            // 
            dataGridView_Accounts.Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right;
            dataGridView_Accounts.ColumnHeadersHeightSizeMode = DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            dataGridView_Accounts.Location = new Point(6, 108);
            dataGridView_Accounts.Name = "dataGridView_Accounts";
            dataGridView_Accounts.RowHeadersWidth = 51;
            dataGridView_Accounts.Size = new Size(970, 440);
            dataGridView_Accounts.TabIndex = 4;
            // 
            // button_CreateAccount
            // 
            button_CreateAccount.AutoSize = true;
            button_CreateAccount.Dock = DockStyle.Fill;
            button_CreateAccount.Location = new Point(604, 3);
            button_CreateAccount.Name = "button_CreateAccount";
            button_CreateAccount.Size = new Size(214, 42);
            button_CreateAccount.TabIndex = 5;
            button_CreateAccount.Text = "Create Account";
            button_CreateAccount.UseVisualStyleBackColor = true;
            // 
            // button_Deposit
            // 
            button_Deposit.AutoSize = true;
            button_Deposit.Dock = DockStyle.Fill;
            button_Deposit.Location = new Point(604, 51);
            button_Deposit.Name = "button_Deposit";
            button_Deposit.Size = new Size(214, 42);
            button_Deposit.TabIndex = 6;
            button_Deposit.Text = "Deposit";
            button_Deposit.UseVisualStyleBackColor = true;
            // 
            // button_Withdraw
            // 
            button_Withdraw.AutoSize = true;
            button_Withdraw.Dock = DockStyle.Fill;
            button_Withdraw.Location = new Point(824, 51);
            button_Withdraw.Name = "button_Withdraw";
            button_Withdraw.Size = new Size(141, 42);
            button_Withdraw.TabIndex = 7;
            button_Withdraw.Text = "Withdraw";
            button_Withdraw.UseVisualStyleBackColor = true;
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
            tableLayoutPanel1.Controls.Add(label_AccountOwner, 0, 0);
            tableLayoutPanel1.Controls.Add(button_Withdraw, 3, 1);
            tableLayoutPanel1.Controls.Add(label_AccountAmount, 0, 1);
            tableLayoutPanel1.Controls.Add(button_Deposit, 2, 1);
            tableLayoutPanel1.Controls.Add(textBox_AccountOwner, 1, 0);
            tableLayoutPanel1.Controls.Add(button_CreateAccount, 2, 0);
            tableLayoutPanel1.Controls.Add(numericUpDown_AccountAmount, 1, 1);
            tableLayoutPanel1.Location = new Point(7, 6);
            tableLayoutPanel1.Name = "tableLayoutPanel1";
            tableLayoutPanel1.RowCount = 2;
            tableLayoutPanel1.RowStyles.Add(new RowStyle());
            tableLayoutPanel1.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
            tableLayoutPanel1.Size = new Size(968, 96);
            tableLayoutPanel1.TabIndex = 8;
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
            Text = "Form1";
            ((System.ComponentModel.ISupportInitialize)numericUpDown_AccountAmount).EndInit();
            ((System.ComponentModel.ISupportInitialize)dataGridView_Accounts).EndInit();
            tableLayoutPanel1.ResumeLayout(false);
            tableLayoutPanel1.PerformLayout();
            ResumeLayout(false);
            PerformLayout();
        }

        #endregion

        private Label label_AccountOwner;
        private Label label_AccountAmount;
        private TextBox textBox_AccountOwner;
        private NumericUpDown numericUpDown_AccountAmount;
        private DataGridView dataGridView_Accounts;
        private Button button_CreateAccount;
        private Button button_Deposit;
        private Button button_Withdraw;
        private TableLayoutPanel tableLayoutPanel1;
    }
}
