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
        });
        closeMenu();
    }
}

function closeMenu() {
    const menu = document.getElementById('loanMenu');
    if (menu) {
        menu.style.display = 'none';
    }
}

function showNotification(message) {
    const notification = document.getElementById('notification');
    if (notification) {
        notification.textContent = message;
        notification.style.display = 'block';
        setTimeout(() => {
            notification.style.display = 'none';
        }, 5000);
    }
}
