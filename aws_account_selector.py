import json
import tkinter as tk
from tkinter import ttk
from tkinter import messagebox

class AWSAccountSelector:
    def __init__(self, root):
        self.root = root
        self.root.title("AWS Account Selector")
        self.root.geometry("600x400")
        
        # Load AWS accounts from JSON
        try:
            with open('aws_accounts.json', 'r') as file:
                self.accounts_data = json.load(file)
        except FileNotFoundError:
            messagebox.showerror("Error", "aws_accounts.json file not found!")
            self.root.destroy()
            return
        except json.JSONDecodeError:
            messagebox.showerror("Error", "Invalid JSON format in aws_accounts.json!")
            self.root.destroy()
            return

        # Create main frame
        main_frame = ttk.Frame(root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

        # Create account selection dropdown
        ttk.Label(main_frame, text="Select AWS Account:").grid(row=0, column=0, sticky=tk.W, pady=5)
        self.account_var = tk.StringVar()
        self.account_dropdown = ttk.Combobox(main_frame, textvariable=self.account_var)
        self.account_dropdown['values'] = [account['name'] for account in self.accounts_data['accounts']]
        self.account_dropdown.grid(row=0, column=1, sticky=(tk.W, tk.E), pady=5)
        self.account_dropdown.bind('<<ComboboxSelected>>', self.on_account_select)

        # Create details frame
        self.details_frame = ttk.LabelFrame(main_frame, text="Account Details", padding="10")
        self.details_frame.grid(row=1, column=0, columnspan=2, sticky=(tk.W, tk.E, tk.N, tk.S), pady=10)

        # Labels for account details
        self.account_number_label = ttk.Label(self.details_frame, text="Account Number:")
        self.account_number_label.grid(row=0, column=0, sticky=tk.W, pady=2)
        self.account_number_value = ttk.Label(self.details_frame, text="")
        self.account_number_value.grid(row=0, column=1, sticky=tk.W, pady=2)

        self.s3_bucket_label = ttk.Label(self.details_frame, text="S3 Bucket:")
        self.s3_bucket_label.grid(row=1, column=0, sticky=tk.W, pady=2)
        self.s3_bucket_value = ttk.Label(self.details_frame, text="")
        self.s3_bucket_value.grid(row=1, column=1, sticky=tk.W, pady=2)

        self.region_label = ttk.Label(self.details_frame, text="Region:")
        self.region_label.grid(row=2, column=0, sticky=tk.W, pady=2)
        self.region_value = ttk.Label(self.details_frame, text="")
        self.region_value.grid(row=2, column=1, sticky=tk.W, pady=2)

        # Configure grid weights
        root.columnconfigure(0, weight=1)
        root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)

    def on_account_select(self, event):
        selected_account = self.account_var.get()
        for account in self.accounts_data['accounts']:
            if account['name'] == selected_account:
                self.account_number_value.config(text=account['account_number'])
                self.s3_bucket_value.config(text=account['s3_bucket'])
                self.region_value.config(text=account['region'])
                break

def main():
    root = tk.Tk()
    app = AWSAccountSelector(root)
    root.mainloop()

if __name__ == "__main__":
    main() 