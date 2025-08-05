using BankApp.BankSystem;
using System.Buffers;

namespace BankApp
{
    public partial class MainForm : Form
    {
        public MainForm()
        {
            InitializeComponent();
        }

        private void MainForm_Load(object sender, EventArgs e)
        {
            RefreshGrid();
        }

        private void button_CreateAccount_Click(object sender, EventArgs e)
        {
            BankAccount account = new(comboBox_AccountSelector.Text, numericUpDown_AccountAmount.Value);
            bool success = BankAccountRepository.AddAccount(account);
            if (!success)
                MessageBox.Show("Failed to make bank account!", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            else
                MessageBox.Show($"Successfully created bank account\nOwner: {account.Owner}\nBalance: {account.Balance}\nId: {account.AccountId}", "Info", MessageBoxButtons.OK, MessageBoxIcon.Information);

            RefreshGrid();
        }

        private void button_DeleteAccount_Click(object sender, EventArgs e)
        {
            bool success = BankAccountRepository.RemoveAccount(x => x.AccountId.ToString().StartsWith(comboBox_AccountSelector.Text));
            if (!success)
                MessageBox.Show("Failed to delete bank account!", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            else
                MessageBox.Show($"Successfully deleted bank account\nOwner: {comboBox_AccountSelector.Text}", "Info", MessageBoxButtons.OK, MessageBoxIcon.Information);

            RefreshGrid();
        }

        private void RefreshGrid()
        {
            dataGridView_Accounts.DataSource = null;
            comboBox_AccountSelector.DataSource = null;

            int count = BankAccountRepository.BankAccounts.Count;

            var accountPool = ArrayPool<BankAccount>.Shared.Rent(count);
            var ownerPool = ArrayPool<string>.Shared.Rent(count);

            try
            {
                BankAccountRepository.CopyTo(accountPool, 0);

                for (int i = 0; i < count; i++)
                    ownerPool[i] = accountPool[i].Owner;

                var accountsForGrid = ArrayPool<BankAccount>.Shared.Rent(count);
                Array.Copy(accountPool, accountsForGrid, count);
                dataGridView_Accounts.DataSource = accountsForGrid;

                var ownersForCombo = ArrayPool<string>.Shared.Rent(count);
                Array.Copy(ownerPool, ownersForCombo, count);
                comboBox_AccountSelector.DataSource = ownersForCombo;
            }
            finally
            {
                ArrayPool<BankAccount>.Shared.Return(accountPool, clearArray: true);
                ArrayPool<string>.Shared.Return(ownerPool, clearArray: true);
            }

        }

        private void button_Deposit_Click(object sender, EventArgs e)
        {
            if (dataGridView_Accounts.SelectedRows.Count == 0)
                return;

            if (dataGridView_Accounts.SelectedRows[0].DataBoundItem is BankAccount account)
            {
                decimal amount = numericUpDown_AccountAmount.Value;

                if (!account.Deposit(amount, out var updated))
                {
                    MessageBox.Show("Invalid deposit amount.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                if (!BankAccountRepository.TryUpdateAccount(account, updated))
                {
                    MessageBox.Show("Failed to update account.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                MessageBox.Show($"Deposited {amount} into {account.Owner}'s account.", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                RefreshGrid();
            }
        }

        private void dataGridView_Accounts_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.Control && e.KeyCode == Keys.C)
            {
                if (dataGridView_Accounts.SelectedRows.Count > 0 &&
                    dataGridView_Accounts.SelectedRows[0].DataBoundItem is BankAccount account)
                {
                    Clipboard.SetText(account.AccountId.ToString());
                    e.Handled = true;
                }
            }
        }

        private void button_Withdraw_Click(object sender, EventArgs e)
        {
            if (dataGridView_Accounts.SelectedRows.Count == 0)
                return;

            if (dataGridView_Accounts.SelectedRows[0].DataBoundItem is BankAccount account)
            {
                decimal amount = numericUpDown_AccountAmount.Value;

                if (!account.Withdraw(amount, out var updated))
                {
                    MessageBox.Show("Invalid withdraw amount or insufficient balance.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                if (!BankAccountRepository.TryUpdateAccount(account, updated))
                {
                    MessageBox.Show("Failed to update account.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                MessageBox.Show($"Withdrew {amount} from {account.Owner}'s account.", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                RefreshGrid();
            }
        }
    }
}