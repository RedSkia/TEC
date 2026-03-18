using System;
using System.Collections.Generic;
using System.Text;

namespace SharedCore.Entities.Banking;

public enum PaymentIntentStatus
{
    Pending = 0,    // Created by merchant, waiting for user
    Authorized = 1, // User clicked "Approve"
    Completed = 2,  // Money moved and Webhook sent
    Expired = 3,    // User took too long
    Cancelled = 4   // User clicked "Cancel"
}
