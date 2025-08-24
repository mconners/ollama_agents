#!/usr/bin/env python3
"""
Distributed AI System Architecture Diagram Generator
Creates a comprehensive PNG visualization of the system design
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, ConnectionPatch
import numpy as np

def create_system_diagram():
    """Create a comprehensive system architecture diagram"""
    
    # Create figure with high DPI for clarity
    fig, ax = plt.subplots(1, 1, figsize=(20, 16))
    ax.set_xlim(0, 20)
    ax.set_ylim(0, 16)
    ax.axis('off')
    
    # Colors for different tiers
    colors = {
        'gateway': '#4CAF50',      # Green
        'primary_ai': '#2196F3',   # Blue  
        'secondary_ai': '#FF9800', # Orange
        'backend': '#9C27B0',      # Purple
        'monitoring': '#F44336',   # Red
        'edge': '#795548',         # Brown
        'network': '#607D8B',      # Blue Grey
        'internet': '#000000'      # Black
    }
    
    # Title
    ax.text(10, 15.5, 'Distributed AI System Architecture', 
            fontsize=24, fontweight='bold', ha='center')
    ax.text(10, 15, '7-Node Containerized Cluster with Load Balancing & High Availability', 
            fontsize=14, ha='center', style='italic')
    
    # Internet/Router Layer
    internet_box = FancyBboxPatch((8, 13.5), 4, 1, 
                                 boxstyle="round,pad=0.1", 
                                 facecolor=colors['internet'],
                                 edgecolor='black', linewidth=2)
    ax.add_patch(internet_box)
    ax.text(10, 14, 'INTERNET', color='white', fontsize=12, fontweight='bold', ha='center')
    
    router_box = FancyBboxPatch((8.5, 12.5), 3, 0.8,
                               boxstyle="round,pad=0.1",
                               facecolor=colors['network'],
                               edgecolor='black', linewidth=1)
    ax.add_patch(router_box)
    ax.text(10, 12.9, 'OpenWRT Router', color='white', fontsize=10, fontweight='bold', ha='center')
    ax.text(10, 12.6, '192.168.1.1', color='white', fontsize=8, ha='center')
    
    # Network backbone
    ax.plot([10, 10], [12.5, 11.5], 'k-', linewidth=3)
    ax.plot([2, 18], [11.5, 11.5], 'k-', linewidth=3)
    ax.text(10, 11.2, '192.168.1.0/24 Network - 27 Devices', 
            fontsize=10, ha='center', style='italic')
    
    # Tier 1: API Gateway (PI51)
    gateway_box = FancyBboxPatch((8, 9.5), 4, 1.5,
                                boxstyle="round,pad=0.1",
                                facecolor=colors['gateway'],
                                edgecolor='black', linewidth=2)
    ax.add_patch(gateway_box)
    ax.text(10, 10.7, 'TIER 1: API GATEWAY', color='white', 
            fontsize=12, fontweight='bold', ha='center')
    ax.text(10, 10.4, 'PI51 (192.168.1.147)', color='white', 
            fontsize=10, fontweight='bold', ha='center')
    ax.text(10, 10.1, 'Raspberry Pi 5 | 8GB RAM | 1TB NVMe', color='white', 
            fontsize=8, ha='center')
    ax.text(10, 9.8, '🌐 Nginx • Kong • Redis • Prometheus • Grafana', color='white', 
            fontsize=8, ha='center')
    
    # Connection from network to gateway
    ax.plot([10, 10], [11.5, 11], 'k-', linewidth=2)
    
    # Tier 2: AI Processing Layer
    # Primary AI (AGX0)
    primary_ai_box = FancyBboxPatch((1, 7), 5, 2,
                                   boxstyle="round,pad=0.1",
                                   facecolor=colors['primary_ai'],
                                   edgecolor='black', linewidth=2)
    ax.add_patch(primary_ai_box)
    ax.text(3.5, 8.5, 'PRIMARY AI HUB', color='white', 
            fontsize=12, fontweight='bold', ha='center')
    ax.text(3.5, 8.2, 'AGX0 (192.168.1.154)', color='white', 
            fontsize=10, fontweight='bold', ha='center')
    ax.text(3.5, 7.9, 'Jetson Orin AGX', color='white', fontsize=9, ha='center')
    ax.text(3.5, 7.6, '64GB RAM | 2TB NVMe', color='white', fontsize=8, ha='center')
    ax.text(3.5, 7.3, '🔥 2048 CUDA Cores', color='white', fontsize=8, ha='center')
    ax.text(3.5, 7.0, '🧠 Ollama (18 Models) | 80% Traffic', color='white', fontsize=8, ha='center')
    
    # Secondary AI (ORIN0)
    secondary_ai_box = FancyBboxPatch((14, 7), 5, 2,
                                     boxstyle="round,pad=0.1",
                                     facecolor=colors['secondary_ai'],
                                     edgecolor='black', linewidth=2)
    ax.add_patch(secondary_ai_box)
    ax.text(16.5, 8.5, 'SECONDARY AI', color='white', 
            fontsize=12, fontweight='bold', ha='center')
    ax.text(16.5, 8.2, 'ORIN0 (192.168.1.157)', color='white', 
            fontsize=10, fontweight='bold', ha='center')
    ax.text(16.5, 7.9, 'Jetson Orin Nano Super', color='white', fontsize=9, ha='center')
    ax.text(16.5, 7.6, '8GB RAM | 1TB NVMe', color='white', fontsize=8, ha='center')
    ax.text(16.5, 7.3, '🔥 1024 CUDA Cores', color='white', fontsize=8, ha='center')
    ax.text(16.5, 7.0, '🎨 ComfyUI | Ollama Backup | 20%', color='white', fontsize=8, ha='center')
    
    # Load balancing connections
    ax.plot([10, 3.5], [9.5, 9], 'k-', linewidth=2)
    ax.plot([10, 16.5], [9.5, 9], 'k-', linewidth=2)
    ax.text(6.5, 9.2, '80%', fontsize=10, fontweight='bold')
    ax.text(13.5, 9.2, '20%', fontsize=10, fontweight='bold')
    
    # Tier 3: Backend Services (PI52)
    backend_box = FancyBboxPatch((7, 4.5), 6, 1.5,
                                boxstyle="round,pad=0.1",
                                facecolor=colors['backend'],
                                edgecolor='black', linewidth=2)
    ax.add_patch(backend_box)
    ax.text(10, 5.7, 'TIER 3: BACKEND SERVICES', color='white', 
            fontsize=12, fontweight='bold', ha='center')
    ax.text(10, 5.4, 'PI52 (192.168.1.247)', color='white', 
            fontsize=10, fontweight='bold', ha='center')
    ax.text(10, 5.1, 'Raspberry Pi 5 | 8GB RAM | 1TB NVMe', color='white', 
            fontsize=8, ha='center')
    ax.text(10, 4.8, '💾 PostgreSQL • Redis • MinIO • PgAdmin', color='white', 
            fontsize=8, ha='center')
    
    # Connections from AI tiers to backend
    ax.plot([3.5, 9], [7, 6], 'k-', linewidth=1)
    ax.plot([16.5, 11], [7, 6], 'k-', linewidth=1)
    
    # Tier 4: Monitoring (PI41)
    monitoring_box = FancyBboxPatch((14, 2.5), 5, 1.5,
                                   boxstyle="round,pad=0.1",
                                   facecolor=colors['monitoring'],
                                   edgecolor='black', linewidth=2)
    ax.add_patch(monitoring_box)
    ax.text(16.5, 3.7, 'MONITORING', color='white', 
            fontsize=12, fontweight='bold', ha='center')
    ax.text(16.5, 3.4, 'PI41 (192.168.1.204)', color='white', 
            fontsize=10, fontweight='bold', ha='center')
    ax.text(16.5, 3.1, 'Raspberry Pi 4 | 2GB RAM', color='white', 
            fontsize=8, ha='center')
    ax.text(16.5, 2.8, '📊 Grafana • Prometheus • Logs', color='white', 
            fontsize=8, ha='center')
    
    # Tier 5: Edge/Utility
    # NANO
    nano_box = FancyBboxPatch((1, 2.5), 4, 1.5,
                             boxstyle="round,pad=0.1",
                             facecolor=colors['edge'],
                             edgecolor='black', linewidth=2)
    ax.add_patch(nano_box)
    ax.text(3, 3.7, 'EDGE DEVICE', color='white', 
            fontsize=12, fontweight='bold', ha='center')
    ax.text(3, 3.4, 'NANO (192.168.1.159)', color='white', 
            fontsize=10, fontweight='bold', ha='center')
    ax.text(3, 3.1, 'Jetson Nano | 2GB RAM', color='white', 
            fontsize=8, ha='center')
    ax.text(3, 2.8, '🔗 Edge Inference | 128 CUDA', color='white', 
            fontsize=8, ha='center')
    
    # PI31
    pi31_box = FancyBboxPatch((7.5, 2.5), 4, 1.5,
                             boxstyle="round,pad=0.1",
                             facecolor=colors['edge'],
                             edgecolor='black', linewidth=2)
    ax.add_patch(pi31_box)
    ax.text(9.5, 3.7, 'UTILITY', color='white', 
            fontsize=12, fontweight='bold', ha='center')
    ax.text(9.5, 3.4, 'PI31 (192.168.1.234)', color='white', 
            fontsize=10, fontweight='bold', ha='center')
    ax.text(9.5, 3.1, 'Raspberry Pi 3 | 1GB RAM', color='white', 
            fontsize=8, ha='center')
    ax.text(9.5, 2.8, '🛠️ Config • Backup • Utils', color='white', 
            fontsize=8, ha='center')
    
    # Data flow arrows and labels
    ax.annotate('', xy=(10, 9.5), xytext=(10, 11.5),
                arrowprops=dict(arrowstyle='<->', lw=2, color='darkgreen'))
    ax.text(10.5, 10.5, 'API\nRequests', fontsize=9, fontweight='bold', color='darkgreen')
    
    # System statistics box
    stats_box = FancyBboxPatch((0.5, 0.5), 8, 1.5,
                              boxstyle="round,pad=0.1",
                              facecolor='lightgray',
                              edgecolor='black', linewidth=1)
    ax.add_patch(stats_box)
    ax.text(4.5, 1.7, 'SYSTEM SPECIFICATIONS', 
            fontsize=12, fontweight='bold', ha='center')
    ax.text(1, 1.4, '• Total RAM: 93GB (83GB Available)', fontsize=9)
    ax.text(1, 1.2, '• Total Storage: 4.7TB (4.1TB Available)', fontsize=9)
    ax.text(1, 1.0, '• GPU Power: 3,200+ CUDA Cores', fontsize=9)
    ax.text(1, 0.8, '• Expected Users: 15-20 Concurrent', fontsize=9)
    
    # Performance box
    perf_box = FancyBboxPatch((11, 0.5), 8, 1.5,
                             boxstyle="round,pad=0.1",
                             facecolor='lightblue',
                             edgecolor='black', linewidth=1)
    ax.add_patch(perf_box)
    ax.text(15, 1.7, 'EXPECTED PERFORMANCE', 
            fontsize=12, fontweight='bold', ha='center')
    ax.text(11.5, 1.4, '• Chat: 40-60 requests/minute', fontsize=9)
    ax.text(11.5, 1.2, '• Images: 3-5 generations/minute', fontsize=9)
    ax.text(11.5, 1.0, '• Code: 20-25 analysis/minute', fontsize=9)
    ax.text(11.5, 0.8, '• High Availability with Failover', fontsize=9)
    
    # Network connections for monitoring
    # Dotted lines to show monitoring connections
    for x_pos in [3.5, 10, 16.5]:
        ax.plot([x_pos, 16.5], [7 if x_pos != 10 else 4.5, 4], 
                'r--', alpha=0.6, linewidth=1)
    
    # Add legend
    legend_elements = [
        patches.Patch(color=colors['gateway'], label='API Gateway'),
        patches.Patch(color=colors['primary_ai'], label='Primary AI'),
        patches.Patch(color=colors['secondary_ai'], label='Secondary AI'),
        patches.Patch(color=colors['backend'], label='Backend Services'),
        patches.Patch(color=colors['monitoring'], label='Monitoring'),
        patches.Patch(color=colors['edge'], label='Edge/Utility')
    ]
    ax.legend(handles=legend_elements, loc='upper right', bbox_to_anchor=(0.98, 0.98))
    
    # Add containerization note
    ax.text(10, 0.2, '🐳 All Services Containerized with Docker Compose for Easy Deployment & Cleanup', 
            fontsize=12, ha='center', fontweight='bold', 
            bbox=dict(boxstyle="round,pad=0.3", facecolor='yellow', alpha=0.7))
    
    plt.tight_layout()
    return fig

if __name__ == "__main__":
    # Create and save the diagram
    fig = create_system_diagram()
    
    # Save with high DPI for crisp image
    output_file = "distributed_ai_system_architecture.png"
    fig.savefig(output_file, dpi=300, bbox_inches='tight', 
                facecolor='white', edgecolor='none')
    
    print(f"✅ System architecture diagram saved as: {output_file}")
    print(f"📏 Image size: 6000x4800 pixels (300 DPI)")
    print(f"📊 Shows complete 7-node distributed AI cluster")
    
    # Also save a smaller web-friendly version
    web_file = "distributed_ai_system_web.png"
    fig.savefig(web_file, dpi=150, bbox_inches='tight',
                facecolor='white', edgecolor='none')
    
    print(f"🌐 Web-friendly version saved as: {web_file}")
    
    plt.show()
