console.log("Debug: Script.js loaded successfully.");

window.addEventListener('message', function(event) {
    console.log("Debug: Event received:", event.data);

    if (event.data.action === 'showLoanMenu') {
        const menu = document.getElementById('loanMenu');
        const options = event.data.options;
        const ul = document.getElementById('loanOptions');
        ul.innerHTML = '';

        options.forEach(option => {
            const li = document.createElement('li');
            li.textContent = `${event.data.currencySymbol}${option.amount} (Interest: ${option.interestRate * 100}%)`;
            li.onclick = () => confirmLoan(option);
            ul.appendChild(li);
        });

        menu.style.display = 'block';
    } else if (event.data.action === 'hideLoanMenu') {
        closeMenu();
    } else if (event.data.action === 'showNotification') {
        showNotification(event.data.message);
    }
});

function confirmLoan(option) {
    if (confirm('Are you sure you want this loan?')) {
        fetch(`https://${GetParentResourceName()}/confirmLoan`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(option)
        }).then(response => {
            if (!response.ok) {
                console.error("Error confirming loan:", response.statusText);
                showNotification("An error occurred while processing your loan. Please try again.");
            }
        }).catch(error => {
            console.error("Network error:", error);
            showNotification("Unable to connect to the server. Please check your connection.");
        });
        closeMenu();
    }
}

function closeMenu() {
    const menu = document.getElementById('loanMenu');
    if (menu) {
        menu.style.display = 'none';
    } else {
        console.warn("Loan menu element not found.");
    }
}

const NOTIFICATION_TIMEOUT = 5000; // Default timeout for notifications

function showNotification(message) {
    const notification = document.getElementById('notification');
    if (notification) {
        notification.textContent = message;
        notification.classList.add('visible');
        notification.classList.remove('hidden');
        setTimeout(() => {
            notification.classList.add('hidden');
            notification.classList.remove('visible');
        }, NOTIFICATION_TIMEOUT);
    } else {
        console.warn("Notification element not found.");
    }
}
