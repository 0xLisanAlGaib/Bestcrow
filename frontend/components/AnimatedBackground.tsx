"use client";

import React, { useEffect, useRef } from "react";

const AnimatedBackground: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const resizeCanvas = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    };

    resizeCanvas();
    window.addEventListener("resize", resizeCanvas);

    const waves: Wave[] = [];
    const waveCount = 4;

    class Wave {
      y: number;
      length: number;
      amplitude: number;
      frequency: number;
      phase: number;
      speed: number;
      color: string;
      private ctx: CanvasRenderingContext2D;
      private canvas: HTMLCanvasElement;

      constructor(y: number, ctx: CanvasRenderingContext2D, canvas: HTMLCanvasElement) {
        this.y = y;
        this.length = 1.5 + Math.random();
        this.amplitude = 25 + Math.random() * 25;
        this.frequency = 0.01;
        this.phase = Math.random() * Math.PI * 2;
        this.speed = 0.009375 + Math.random() * 0.009375;
        this.color = `rgba(173, 216, 230, ${0.1 + Math.random() * 0.2})`;
        this.ctx = ctx;
        this.canvas = canvas;
      }

      update() {
        this.phase += this.speed;
        if (this.phase > Math.PI * 2) {
          this.phase -= Math.PI * 2;
        }
      }

      draw() {
        this.ctx.beginPath();
        this.ctx.moveTo(0, this.canvas.height);
        for (let x = 0; x < this.canvas.width; x++) {
          const y = this.y + Math.sin(x * this.frequency + this.phase) * this.amplitude;
          this.ctx.lineTo(x, y);
        }
        this.ctx.lineTo(this.canvas.width, this.canvas.height);
        this.ctx.fillStyle = this.color;
        this.ctx.fill();
      }
    }

    function createWaves() {
      for (let i = 0; i < waveCount; i++) {
        waves.push(new Wave(canvas.height * (0.3 + i * 0.2), ctx, canvas));
      }
    }

    function animateWaves() {
      ctx.fillStyle = "rgb(10, 25, 47)";
      ctx.fillRect(0, 0, canvas.width, canvas.height);

      for (const wave of waves) {
        wave.update();
        wave.draw();
      }
      requestAnimationFrame(animateWaves);
    }

    createWaves();
    animateWaves();

    return () => {
      window.removeEventListener("resize", resizeCanvas);
    };
  }, []);

  return <canvas ref={canvasRef} className="fixed inset-0 w-full h-full" />;
};

export default AnimatedBackground;
