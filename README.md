# Openmines

A simple Minesweeper-style game built with Ruby on Rails.

## Overview

Openmines is a web-based Minesweeper game where users can reveal cells, flag mines, and try to clear the board without hitting any bombs.

The project focuses on core game logic and extend the game to multiplayers version with bigger playground.

## Tech Stack

- Ruby on Rails 8
- SQLite (development and production)
- Stimulus.js for interactivity
- HTML/CSS for the frontend
- Deployed with Kamal on a VPS

## Features

- Generate a new game with custom grid size
- Reveal cells and automatically uncover adjacent empty cells
- Flag potential mines
- Track game status: win or lose
- Responsive and interactive interface

## Purpose

This project demonstrates:

- Implementing game logic in Rails
- Using Stimulus.js for interactive frontend behavior
- Structuring a Rails project with both frontend and backend logic
- Deploying a Rails app to a VPS for public use


What do i want for this game:
Multiplayer
Turbo streaming
Scalable boards (even for big ones)

Models:
Actions (history is good)
Games

How it works:
Use seed to generate mines deterministically
Broadcast only changed coordinates
