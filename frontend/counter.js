    fetch(`${VISITOR_API_URL}/count`)
      .then(response => response.json())
      .then(data => {
        document.getElementById('visitor-count').textContent = data.count;
      })
      .catch(error => {
        console.error('Error fetching visitor count:', error);
        document.getElementById('visitor-count').textContent = 'Error';
      });
